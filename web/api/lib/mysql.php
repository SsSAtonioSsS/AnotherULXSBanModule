<?php
    class MSQL
    {
        private mysqli $connect;
        
        public function __construct(string $host, string $user, string $passwd, string $db, int $port = 3306)
        {
            $this->connect = $this->createsql($host, $user, $passwd, $db, $port);
        }

        protected function __destruct()
        {
            $this->connect->close();
        }
        
        protected function createsql(string $host, string $user, string $passwd, string $db, int $port)
        {
            $l = new mysqli($host, $user, $passwd, $db, $port);
            if (!$l) {
                throw new Exception("Can't connect to MySQL.\n Error: ".$l->connect_error);
            } else {
                $l->set_charset('utf8'); //utf8mb4
                //$l->autocommit(true);
            }
            return $l;
        }
        
        protected function query(string $query, string $where = '', string $other = '')
        {
            $query = $query . $where . $other;
            //return $query;
            $this->connect->begin_transaction();
            try {
                $r = $this->connect->query($query);
                $this->connect->commit();
                return $r;
            } catch (Exception $e) {
                $this->connect->rollback();
                print($e);
                return -1;
            }
        }

        private function select(string $what, string $from, string $where, string $other = '')
        {
            $q = "SELECT " . $what . " FROM ". $from;
            return $this->query($q, $where, $other);
        }

        public function where(array $ar)
        {
            $wh = '';
            foreach ($ar as $col => $val) {
                $val = is_int($val) ? $val : "'" . $val . "'";

                if ($col === array_key_first($where)) {
                    $wh = $wh . " WHERE " . $col . " = " . $val;
                } else {
                    $wh = $wh . " AND " . $col . " = " . $val;
                }
            }
            return $wh;
        }

        public function update(string $from, array $what, string $where)
        {
            if (!$what) {
                throw new Exception("There are no values ​​for SET.");
            }

            if (!$where) {
                throw new Exception("There are no values ​​for WHERE.");
            }

            $q = "UPDATE " . $from . " SET ";

            foreach ($what as $col => $val) {
                if ($col === array_key_first($what)) {
                    $q = $q . $col . " = " . $val;
                } else {
                    $q = $q . ", " . $col . " = " . $val;
                }
            }

            return $this->query($q, $where);
        }
        
        public function delete(string $from, string $where)
        {
            if (!$where) {
                throw new Exception("There are no values ​​for WHERE.");
            }

            $q = "DELETE FROM " . $from;

            return $this->query($q, $where);
        }
        
        public function insert(string $from, array $what)
        {
            if (!$what) {
                throw new Exception("There are no values ​​for INSERT.");
            }

            $q = "INSERT INTO " . $from;
            $q1 = "";
            $q2 = "";

            foreach ($what as $col => $val) {
                if ($col === array_key_first($what)) {
                    $q1 = $col;
                    $q2 = $val;
                } else {
                    $q1 = $q1 . ', ' . $col;
                    $q2 = $q2 . ', ' . $val;
                }
            }
            $q = $q . ' (' . $q1 . ') VALUES (' . $q2 . ')';
            
            return $this->query($q);
        }

        public function selOne(string $what, string $from, string $where = '')
        {
            if (strlen($where) < 7) {
                throw new Exception("There are no values ​​for WHERE.");
            }
            $result = $this->select($what, $from, $where, ' LIMIT 1');
            
            if ($result == -1) {
                print($this->connect->error);
                return [];
            }

            return $result ? $result->fetch_assoc() : $result;
        }

        public function selAll(string $what, string $from, string $where = '')
        {
            $result = $this->select($what, $from, $where);
            
            if ($result == -1) {
                print($this->connect->error);
                return [];
            }

            return $result ? $result->fetch_all(MYSQLI_ASSOC) : $result;
        }
    }
