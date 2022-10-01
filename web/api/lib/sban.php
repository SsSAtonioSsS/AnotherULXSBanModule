<?php
    class SBAPI
    {
        private string $sid;
        private string $prefix;
        private MSQL $db;
        
        public function __construct(string $ServerID, string $prefix, MSQL $db)
        {
            $this->sid = $ServerID;
            $this->prefix = $prefix;
            $this->db = $db;
        }

        private function getAid(string $steamid)
        {
            $admin = $this->db->selOne('*', $this->prefix.'_admins', " WHERE authid = '$steamid' AND (expired = 0 OR expired > UNIX_TIMESTAMP())");
            return $admin['aid'] ? intval($admin['aid']) : null;
        }

        private function getAdminStatus($res, array $buf = [], string $type = null)
        {
            if (!$type) {
                if ($res) {
                    $buf['aid'] = $res;
                    $qr = $this->db->selOne('*', $this->prefix.'_admins_servers_groups', " WHERE admin_id = " . $buf['aid'] . " AND srv_group_id = -1 AND server_id = $this->sid");
                    
                    return $this->getAdminStatus($qr, $buf, "checkadmingroup");
                } else {
                    return ['isAdmin' => false];
                }
            } elseif ($type == "checkadmingroup") {
                if ($res) {
                    $qr = $this->db->selOne('*', $this->prefix.'_admins', " WHERE aid = " . $res['admin_id']);
                    return $this->getAdminStatus($qr, $buf, 'sendgroup');
                } else {
                    $qr = $this->db->selAll('*', $this->prefix.'_servers_groups sg', " WHERE sg.server_id = $this->sid AND (SELECT asg.srv_group_id FROM " . $this->prefix . "_admins_servers_groups asg WHERE asg.admin_id = " . $buf['aid'] . " AND asg.srv_group_id = sg.group_id) >= 1");
                    return $this->getAdminStatus($qr, $buf, 'servergroupmatch');
                }
            } elseif ($type == 'servergroupmatch') {
                if ($res >= 1) {
                    $qr = $this->db->selOne('*', $this->prefix.'_admins', " WHERE aid = " . $buf['aid']);
                    return $this->getAdminStatus($qr, $buf, 'sendgroup');
                } else {
                    return ['isAdmin' => false];
                }
            } elseif ($type == 'sendgroup') {
                return ['isAdmin' => true,
                'aid' => $buf['aid'],
                'password' => ($res['srv_password'] ? hash("sha256", $res['srv_password']) : false),
                'group' => $res['srv_group'],
                'permissions' => $res['srv_flags'] != '' ? ['access' => true,
                'flags' => array_fill_keys(str_split($res['srv_flags']), true)] : ['access' => false],
                'immunity' => $res['immunity']];
            }
        }

        public function getActiveBan(string $steamid = '%', string $IP = '%')
        {
            $ban = $this->db->selOne('*', $this->prefix.'_bans', " WHERE authid LIKE '$steamid' AND ip LIKE '$IP' AND (RemoveType IS NULL OR RemoveType != 'U') AND (length = 0 OR ends > UNIX_TIMESTAMP())");

            return ["banned" => $ban ? true : false, 'res' => $ban];
        }

        public function getBans(int $limit, string $steamid = '')
        {
            $bans = [];
            
            if ($steamid == '') {
                $bans = $this->db->selAll('a.user as admin, b.aid, b.bid, b.sid, b.name, b.reason, b.authid, b.created, b.ends', $this->prefix.'_bans b', ' INNER JOIN '.$this->prefix."_admins a ON b.aid = a.aid WHERE b.RemoveType is null ORDER BY b.created DESC LIMIT $limit");
            } else {
                $bans = $this->db->selAll('bid', $this->prefix.'_bans', " WHERE authid = '$steamid'");
            }

            return ['res' => $bans];
        }

        public function reportBlock(int $bid, string $name, int $time = null)
        {
            $time = $time ? $time : time();
            $ins = $this->db->insert($this->prefix.'_banlog', ['sid' => $this->sid, 'time' => $time, 'name' => "'$name'", 'bid' => $bid]);

            return ['reported' => $ins];
        }

        public function updateBan(string $steamid, int $time, string $reason, string $name)
        {
            if (!$name || strlen($name) == 0) {
                $name = "[Unknown]";
            }
        
            $upd = $this->db->update($this->prefix.'_bans', ['ends' => "created + $time", 'length' => $time, 'name' => "'$name'", 'reason' => "'$reason'"], " WHERE authid = '$steamid' AND RemoveType IS NULL");

            return ['updated' => $upd];
        }
    
        public function canUnban(string $steamid, int $aid, bool $access = false)
        {
            $where = "";
            if ($access == 'false') {
                $where = " AND aid = ".$aid;
            }
            $s = $this->db->selOne('*', $this->prefix.'_bans', " WHERE authid = '$steamid' AND RemoveType is null".$where);

            return ['can' => $s ? true : false];
        }
    
        public function unBan(string $steamid, int $aid, int $time = null, string $reason)
        {
            $time = $time ? $time : time();
            $reason = $reason ? $reason : 'noinfo';
            
            $upd = $this->db->update($this->prefix.'_bans', ['RemovedOn' => $time, 'RemovedBy' => $aid, 'RemoveType' => "'U'", 'ureason' => "'$reason'"], " WHERE authid = '$steamid' AND RemoveType IS NULL");

            return ['unbanned' => $upd];
        }

        public function newBan(string $ip = null, string $steamid, string $name, int $time = null, int $length, string $reason = null, int $aid)
        {
            $ban = $this->getActiveBan($steamid);
            $time = $time ? $time : time();
            $reason = $reason ? $reason : 'noinfo';
            $ip = $ip ? $ip : 'unknown';

            if ($ban['banned']) {
                return ['added' => false, 'reason' => "alreadybanned"];
            }
            
            $ins = $this->db->insert($this->prefix.'_bans', ['ip' => "'$ip'", 'authid' => "'$steamid'", 'name' => "'$name'", 'created' => $time, 'ends' => $time+$length, 'length' => $length, 'reason' => "'$reason'", 'aid' => $aid, 'sid' => $this->sid]);

            return ['added' => $ins];
        }

        public function getComms(string $steamid)
        {
            $comms = $this->db->selAll('c.bid, c.aid, c.authid, c.length, c.reason, c.RemoveType, c.ends, a.user, c.type', $this->prefix.'_comms AS c', ' LEFT JOIN '.$this->prefix."_admins AS a ON a.aid = c.aid WHERE c.authid = '$steamid' AND (c.RemoveType IS NULL OR c.RemoveType != 'U') AND (c.length = 0 OR c.ends > UNIX_TIMESTAMP())");
            if (count($comms) == 0) {
                return ['comms' => false];
            }

            foreach ($comms as $comm) {
                if ($comm['type'] == 1) {
                    $ret['micro'] = $comm;
                } else {
                    $ret['chat'] = $comm;
                }
            }

            return ['comms' => true, 'res' => $ret];
        }

        public function canUnComm(string $steamid, int $aid, int $type, bool $access = false)
        {
            $comms = $this->getComms($steamid);
            $comms = $comms['res'];
            
            if (!$comms['micro'] && $type == 1 || !$comms['chat'] && $type == 2) {
                return ['can' => false, 'reason' => 'notcommed'];
            }
            
            $comms = $type == 1 ? $comms['micro'] : $comms['chat'];

            if (!$access && $comms['aid'] != $aid) {
                return ["can" => false, "reason" => "notenoughaccess"];
            }

            return ['can' => true];
        }

        public function unComm(string $steamid, int $aid, int $time = null, int $type, string $reason = null)
        {
            $time = $time ? $time : time();
            $reason = $reason ? $reason : 'noinfo';
            
            $comms = $this->getComms($steamid);
            $comms = $comms['res'];

            if (!$comms['micro'] && $type == 1 || !$comms['chat'] && $type == 2) {
                return ['uncommed' => false, 'reason' => 'notcommed'];
            }
            
            if ($type == 1) {
                $comms = $comms['micro'];
            } elseif ($type == 2) {
                $comms = $comms['chat'];
            } else {
                return ['uncommed' => false, 'reason' => 'typeofcommnotreq'];
            }

            $upd = $this->db->update($this->prefix.'_comms', ['RemovedOn' => $time, 'RemovedBy' => $aid, 'RemoveType' => "'U'", 'ureason' => "'$reason'"], ' WHERE bid = '.$comms['bid']);

            return ['uncommed' => $upd];
        }

        public function newComm(string $steamid, string $name, int $time = null, int $length, string $reason = null, int $aid, int $type)
        {
            $time = $time ? $time : time();
            $reason = $reason ? $reason : 'noinfo';

            $comms = $this->getComms($steamid);
            $comms = $comms['res'];

            if ($comms['micro'] && $type == 1 || $comms['chat'] && $type == 2) {
                return ['added' => false, 'reason' => 'alreadyblocked'];
            }

            $ins = $this->db->insert($this->prefix.'_comms', ['authid' => "'$steamid'", 'name' => "'$name'", 'created' => $time, 'ends' => $time+$length, 'length' => $length, 'reason' => "'$reason'", 'aid' => $aid, 'sid' => $this->sid, 'type' => $type]);

            return ['added' => $ins];
        }

        public function getAdmin(string $steamid)
        {
            $aid = $this->getAid($steamid);
            $res = $this->getAdminStatus($aid);
            return $res;
        }
    }
