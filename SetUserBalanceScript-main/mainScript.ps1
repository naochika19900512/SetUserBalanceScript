if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
        Exit;
    }
}
$XML = [XML](Get-Content -Encoding default .\config.xml)
$servercommand = $XML.root.ConfigList.ServerCommandExePath
$accountList = $XML.root.ConfigList.AccountList.Split(",")
$groupList= $XML.root.GroupList.Group
$userList = Import-Csv .\user_list.csv -Encoding Default
$logFolder = Join-Path .\ "log"
$falseLimit = $XML.GroupList.Group.Count
$Time = (Get-Date).ToString("yyyy-MM-dd")

<#$foldername�Ŏw�肵���f�B���N�g���ɓ���̃f�B���N�g�������邩���m�F�B�f�B���N�g�����Ȃ��ꍇ�͍쐬����B#>
 function confirm_directory($path){
    if(Test-Path $path){
        }else{
            New-Item $path -ItemType Directory
        }
}

#���O�t�@�C���𐶐�����
function log_file($LogString){
    $logfile =  $Time + "_" +  "setuserbalance.log"
    $logpath = Join-Path $logFolder $logfile
    $Now = Get-Date
    # Log �o�͕�����Ɏ�����t��(YYYY/MM/DD HH:MM:SS.MMM $LogString)
    $Log = $Now.ToString("yyyy/MM/dd HH:mm:ss.fff") + " "
    $Log += $logstring
    Write-Output $Log | Out-File -FilePath $logpath -Encoding Default -append
}

#����/���s���L�q����֐�
function resultMsg1($result){
    if($result){
        return "INFO","�|�C���g��ݒ肵�܂����B"
}else{
    return "ERROR","�R�}���h�̎��s�Ɏ��s���܂����Bconfig.xml�̐ݒ���e���m�F���Ă��������B"
    }
}

#�|�C���g���Z�b�g����֐�
function setUserPoint(){
	foreach($user in $userList){
        $falseCount = 0
   		foreach($group in $XML.root.GroupList.Group){
            if($user.�O���[�v -eq $group.Label){
                $pointList = $group.Point.Split(",")
                for ($i=0; $i -lt $pointList.Count; $i++){
                    if([string]::IsNullOrEmpty($accountList[0])){
                        if(($pointList[0] -ge 0) -and ($pointList.Length -le 1)){
                            cmd /C $servercommand set-user-account-balance $user.���O $pointList[0] �|�C���g�ǉ�����
                            $result = echo $?
                            $info,$massage = resultMsg1($result)
                            log_file($info,$user.���O,$group.Label,"�r���g�C���A�J�E���g",$pointList[0],$massage)
                        }else{
                            log_file("ERROR",$user.���O,$group.Label,"config.xml -> Point�^�O�ɕs���Ȓl�����o����܂����B�����𒆒f���܂��B�ݒ���m�F���Ă��������B")
                            exit
                        }
                    }else{
                        if($pointList[$i] -ge 0){
                            cmd /C $servercommand set-user-account-balance $user.���O $pointList[$i] �|�C���g�ǉ����� $accountList[$i]
                            $result = echo $?
                            $info,$massage = resultMsg1($result)
                            log_file($info,$user.���O,$group.Label,$accountList[$i],$pointList[$i],$massage)
                        }else{
                            log_file("INFO",$user.���O,$group.Label,"config.xml -> Point�^�O��",$accountList[$i],"�����ɒl�����͂���Ă��Ȃ����߁A�������X�L�b�v���܂��B")
                        }
                    }
                 }
             }else{
                $falseCount += 1
                if($falseCount -eq $falseLimit){
                    log_file("ERROR",$user.���O,"��v����O���[�v������܂���")
                }
            }
        }
    }
}

#log�t�H���_�̍쐬
confirm_directory($logFolder)
#�����J�n
log_file("<Start>")
$pslogfile =  $Time + "_" +  "powershell.log"
$pslogpath = Join-Path $logFolder $pslogfile
Start-Transcript $pslogpath -Append
#�|�C���g�ݒ菈��
setUserPoint
#�����I��
log_file("<End>")
Stop-Transcript
