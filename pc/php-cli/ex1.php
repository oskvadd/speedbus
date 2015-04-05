<?php
//
function strtohex($string)
{
    $hex='';
    for ($i=0; $i < strlen($string); $i++)
        {
            $hex .= dechex(ord($string[$i]));
        }
    return $hex;
}

//

class spb
{
    public $fp;
    public $devlist;
    public $evelist;
    public $gtvlist;
    public $prmlist;

    private $is_root;
    private $status;
  
    public function __construct($host,$username,$password, $port = 306)
    {
        $this->devlist = array();
        $this->evelist = array();
        $this->gtvlist = array();
        $this->prmlist = array();

        if(isset($password)){
            $this->spb_connect($host,$username,$password , $port); 
        }
    }
  
    public function spb_connect($host,$username,$password , $port = 306){
        $this->fp = fsockopen("ssl://$host", 306, $errno, $errstr, 30);
        if (!$this->fp) {
            $this->status = 0;
            return 0;
        } else {
            $out = "$username\n$password";
            fwrite($this->fp, $out);
            if(!feof($this->fp)) {
                $recv = fgets($this->fp, 128);
                if(strpos($recv, "Login Failed") !== FALSE){
                    die("Login Failed!!\n");
                    fclose($this->fp);
                    $this->status = -1; // login fail
                    return -1; // login failed
                }
            }
        }
        // Check if i am root
        $is_root=0;
        if(strpos($recv, "root")){
            $is_root=1;
        }
        // 

        // Make the dev list
        while(!feof($this->fp)){
            $recv = fgets($this->fp, 128);
            if(strpos($recv, "devlistadd") !== FALSE){
                $develem = array();
                sscanf($recv, "devlistadd %s %s", $dev_addr, $dev_id);
                $develem["addr"] = $dev_addr;
                $develem["devid"] = $dev_id;
                array_push($this->devlist, $develem);
            }

            if(strpos($recv, "eveadd") !== FALSE){
                $eveelem = array();
                $argc = sscanf($recv, "eveadd %d %d %[^\n]", $eve_devid, $eve_nr, $eve_dscr);
                $eveelem["devid"] = $eve_devid;
                $eveelem["evenr"] = $eve_nr;
                if($argc > 2){
                    $eveelem["dscr"] = $eve_dscr;
                }
                array_push($this->evelist, $eveelem);
            }

            if(strpos($recv, "getvadd") !== FALSE){
                $gtvelem = array();
                $argc = sscanf($recv, "getvadd %d %d %d %[^\n]", $gtv_devid, $gtv_evenr, $gtv_varnr, $gtv_dscr);
                $gtvelem["devid"] = $gtv_devid;
                $gtvelem["evenr"] = $gtv_evenr;
                $gtvelem["varnr"] = $gtv_varnr;
                $gtvelem["dscr"] = $gtv_dscr;
                array_push($this->gtvlist, $gtvelem);	
            }

            if(strpos($recv, "paramlp") !== FALSE){
                $prmelem = array();
                $argc = sscanf($recv, "paramlp %d %d %d %d %[^\n]", $prm_devid, $prm_prmnr, $prm_type, $prm_readonly, $prm_dscr);
                $prmelem["devid"] = $prm_devid;
                $prmelem["prmnr"] = $prm_prmnr;
                $prmelem["type"] = $prm_type;
                $prmelem["readonly"] = $prm_readonly;
                $prmelem["dscr"] = $prm_dscr;
                array_push($this->prmlist, $prmelem);	
            }
      
            if(strpos($recv, "paramlu") !== FALSE){
                $argc = sscanf($recv, "paramlu %d %d %[^\n]", $prm_devid, $prm_prmnr, $prm_unit);
                for($i=0; $i < count($this->prmlist); $i++){
                    if($this->prmlist[$i]["devid"] == $prm_devid && $this->prmlist[$i]["prmnr"] == $prm_prmnr){
                        $this->prmlist[$i]["unit"] = $prm_unit;
                    }
                }
                $prm_unit = "";
            }


            if(strpos($recv, "udevlist") !== FALSE){
                break;
            }
        }
        //
 
        return 1;
    }

    public function spb_errc(){
        // everything under 1 is error, so just take this in to a if statement

        if(!$this->fp){
            return 0; // Not connected
        }
    
        if($this->status){
            return $this->status;
        }
    
        return 1;
    }
  
    public function spb_errcm(){
        switch($this->status){
        case 0:
            return "Unable to make a connection.";
        case -1:
            return "Wrong login credentials.";
        default:
            if($this->status){
                return "Connection seems fine";
            }
        }
    }

    public function spb_event_exec($devid, $event, $vars = ""){
        $out = "evexec $devid $event $vars\n";
        fwrite($this->fp, $out);
        while($recv = fread($this->fp, 128)){
            if(strpos($recv, "good") !== FALSE){
                return 1;
            }
            if(strpos($recv, "info Cant send") !== FALSE || strpos($recv, "info Error when") !== FALSE){
                return 0;
            }
        }
    }

    public function spb_send($out){
        fwrite($this->fp, $out);
        while($recv = fread($this->fp, 128)){
            if(1){
                print("hej\n" . $recv . "\n\n");
                if(strpos($recv, "send " . chr(20) . chr(20) . chr(0) . chr(0) . chr(0x03) . chr(0x00) . chr(0x00)) !== FALSE){
                    return 1;
                }
                if(strpos($recv, "info Cant send") !== FALSE || strpos($recv, "info Error when") !== FALSE){
                    return 0;
                }
            }else{
                if(strpos($recv, "good") !== FALSE){
                    return 1;
                }
                if(strpos($recv, "info Cant send") !== FALSE || strpos($recv, "info Error when") !== FALSE){
                    return 0;
                }
            }
        }
    }

    public function spb_getvar_async($devid, $var){
        $out = "getvarasync $devid $var\n";
        fwrite($this->fp, $out);
        while($recv = fread($this->fp, 128)){
            if(strpos($recv, "getvarasync") !== FALSE){
                print($recv);
                return 1;
            }
            if(strpos($recv, "info Cant send") !== FALSE || strpos($recv, "info Error when") !== FALSE){
                return 0;
            }
        }
    }
  
    public function spb_getparam_info($devid, $param){
        for($i=0; $i < count($this->prmlist); $i++){
            if($this->prmlist[$i]["devid"] == $devid && $this->prmlist[$i]["prmnr"] == $param){
                return $this->prmlist[$i];
            }
        }	
    }

    public function spb_getparam($devid, $param){
        $pinfo = $this->spb_getparam_info($devid, $param);
        $descr = $pinfo["dscr"];
        if(isset($pinfo["unit"]))
            $unit = $pinfo["unit"];
        else
            $unit = "";
        
        print($descr . ": " . $this->spb_getparam_val($devid, $param) . $unit . "\n");
        return 1;
    }

    public function spb_getparam_val($devid, $param){
        $out = "getparam $devid $param\n";
        fwrite($this->fp, $out);
        while($recv = fread($this->fp, 128)){
            if(strpos($recv, "pparam $devid $param") !== FALSE){
                $argc = sscanf($recv, "pparam %d %d %[^\n]", $prm_devid, $prm_prmnr, $value);
                return $value;
            }
            if(strpos($recv, "info Cant send") !== FALSE || strpos($recv, "info Error when") !== FALSE){
                return "";
            }
        }
    }


    public function spb_setparam($devid, $param, $arg){
        $out = "setparam $devid $param $arg\n";
        fwrite($this->fp, $out);
        while($recv = fread($this->fp, 128)){
            if(strpos($recv, "pparam $devid $param") !== FALSE){
                $argc = sscanf($recv, "pparam %d %d %[^\n]", $prm_devid, $prm_prmnr, $value);
                $pinfo = $this->spb_getparam_info($devid, $param);
                $descr = $pinfo["dscr"];
                if(isset($pinfo["unit"]))
                    $unit = $pinfo["unit"];
                else
                    $unit = "";
	
                print($descr . ": " . $value . $unit . "\n");
                return 1;
            }
            if(strpos($recv, "info Cant send") !== FALSE || strpos($recv, "info Error when") !== FALSE){
                return 0;
            }
        }
    }

}
$spb = new spb("speedbus.org", "oscar", "1500");
if(!$spb->spb_errc()){
    die($spb->spb_errcm() . "\n");
}

switch($argv[1]){
case "getvar": 
    if($spb->spb_getvar_async($argv[2], $argv[3])){
        print("Succefully executed the event!\n");
    }else{
        print("Error executing the event, check event and devid nr!\n");
    }
    break;

case "evexec":
    if($spb->spb_event_exec($argv[2], $argv[3], $argv[4])){
        print("Succefully executed the event!\n");
    }else{
        print("Error executing the event, check event and devid nr!\n");
    }
    break;

case "ping": 
    while(1){
        $out = "ping " . microtime(true) . "\n";
        fwrite($spb->fp, $out);
        $recv = "                                                                                                                                                    ";
        while($recv = fread($spb->fp, 128)){
            if(strpos($recv,"ping") > -1){
                break;}
        }
        $val = substr($recv,5,strpos($recv, "\n")-1);
        print("Pinged in " . round(1000*(microtime(true) - (float)$val)) . "ms\n");
        sleep(1);
    }
    break;
 
case "getparam":
    if($spb->spb_getparam($argv[2], $argv[3])){
        print("Succefully executed the event!\n");
    }else{
        print("Error executing the event, check event and devid nr!\n");
    }
    break;

case "setparam":
    if($spb->spb_setparam($argv[2], $argv[3], $argv[4])){
        print("Succefully executed the event!\n");
    }else{
        print("Error executing the event, check event and devid nr!\n");
    }
    break;



case "sendlcd1":
    $usl = 0;

    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x01) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . "\n");
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x02) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . "\n");
    usleep($usl);
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x03) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . "\n");
    usleep($usl);
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x04) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . "\n");
    usleep($usl);
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x05) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . "\n");
    usleep($usl);
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x06) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . "\n");
    usleep($usl);
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x07) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . "\n");
    usleep($usl);
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x08) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . chr(100) . "\n");
    break;


case "sendlcd2":
    $usl = 0;

    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x01) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . "\n");
    usleep($usl);
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x02) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . "\n");
    usleep($usl);
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x03) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . "\n");
    usleep($usl);
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x04) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . "\n");
    usleep($usl);
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x05) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . "\n");
    usleep($usl);
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x06) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . "\n");
    usleep($usl);
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x07) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . "\n");
    usleep($usl);
    $spb->spb_send("send " . chr(0x0) . chr(0x0) . chr(20) . chr(20) . chr(0x03) . chr(0x01) . chr(0x04) . chr(0x08) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . chr(67) . "\n");
    break;
    
case "cc":
    stream_set_blocking($spb->fp, 0);
    $handle = fopen ("php://stdin","r");
    while(1){
        print("Send command> ");
        $line = fgets($handle);
        if(trim($line) == "q" || trim($line) == "quit")
            die("ByeBye\n");
        fwrite($spb->fp, $line);
        usleep(20000);
        for($i = 0; $i < 10; $i++){
            $buf = fread($spb->fp, 2048);
            if(strlen($buf) < 1){
                break;}
            print($buf);
        }
    }
break;

case "listparam":
    foreach($spb->prmlist as $prm){
        if($prm["devid"] == $argv[2]){
            print($prm["prmnr"] . ": " . $prm["dscr"] . "\n");
        }
    }
    break;

}
//die("Bye");
//print_r($spb->devlist);
//print_r($spb->evelist);
//print_r($spb->gtvlist);
//print_r($spb->prmlist);

?>