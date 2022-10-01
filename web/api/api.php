<?php
    header('Content-type: application/json');

    $url = parse_url($_SERVER['REQUEST_SCHEME'].'://'.$_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI']);
    parse_str(urldecode($url['query']), $query);
    
    if ($query['key'] != 'AnyKeyAPI') {
        echo json_encode(array("err" => 'Uncorrect API key!'));
        die();
    }
    if (!$query['sid']) {
        echo json_encode(array("err" => 'Server ID not defined!'));
        die();
    }
    define('IN_SB', true);
    include_once '../data/config.php';

    require 'lib/mysql.php';
    require 'lib/sban.php';

    function resFormat(array $res, bool $success = true, string $def = '')
    {
        return ['response' => $success ? ['success' => true, 'body' => $res] : ['success' => false, 'def' => $def]];
    }

    $sess = new MSQL(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);
    $sban = new SBAPI($query['sid'], DB_PREFIX, $sess);

    switch ($query['op']) {
        case 'getadmin':
            $res = $sban->getAdmin($query['id']);
            break;
        case 'getblocks':
            $steam = $query['id'] ? $query['id'] : '%';
            $ip = $query['ip'] ? $query['ip'] : '%';

            $res = $sban->getActiveBan($steam, $ip);
            if ($res['banned']) {
                $res = ['ban' => true, 'res' => $res['res']];
                break;
            }
            $res = $sban->getComms($query['id']);
            break;
        case 'banlog':
            $res = $sban->reportBlock($query['bid'], $query['name'], $query['time']);
            break;
        case 'retrievebans':
            $limit = $query['limit'] ? $query['limit'] : 120;
            $res = $sban->getBans($limit);
            break;
        case 'bans':
            $res = $sban->getBans(0, $query['id']);
            break;
        case 'updateban':
            $res = $sban->updateBan($query['id'], $query['length'], $query['reason'], $query['name']);
            break;
        case 'canunban':
            $access = $query['unall'] ? $query['unall'] : false;
            $res = $sban->canUnban($query['id'], $query['aid'], $query['unall']);
            break;
        case 'unban':
            $res = $sban->unBan($query['id'], $query['aid'], $query['time'], $query['reason']);
            break;
        case 'newban':
            $res = $sban->newBan($query['ip'], $query['id'], $query['name'], $query['time'], $query['length'], $query['reason'], $query['aid']);
            break;
        case 'canuncomm':
            $access = $query['unall'] ? $query['unall'] : false;
            $res = $sban->canUnComm($query['id'], $query['aid'], $query['type'], $query['unall']);
            break;
        case 'uncomm':
            $res = $sban->unComm($query['id'], $query['aid'], $query['time'], $query['type'], $query['reason']);
            break;
        case 'newcomm':
            $res = $sban->newComm($query['id'], $query['name'], $query['time'], $query['length'], $query['reason'], $query['aid'], $query['type']);
            break;
        default:
            echo json_encode(resFormat([], false, 'Unkown Operation'));
            return;
    }
    echo json_encode(resFormat($res));
    return;
