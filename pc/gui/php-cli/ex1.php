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
  private $is_root;
  private $status;
  
  public function __construct($host,$username,$password, $port = 306)
  {
    $this->devlist = array();
    $this->evelist = array();
    $this->gtvlist = array();
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


}
$spb = new spb("speedbus.org", "root", "toor");
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
}
print_r($spb->devlist);
print_r($spb->evelist);
print_r($spb->gtvlist);

?>