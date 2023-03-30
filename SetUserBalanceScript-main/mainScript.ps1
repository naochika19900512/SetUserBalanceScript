if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")) { Start-Process powershell.exe "-File `"$PSCommandPath`"" -Verb RunAs; exit }
$XML = [XML](Get-Content -Encoding default .\config.xml)
$servercommand = $XML.root.ConfigList.ServerCommandExePath
$accountList = $XML.root.ConfigList.AccountList.Split(",")
$groupList= $XML.root.GroupList.Group
$userList = Import-Csv .\user_list.csv -Encoding Default
$logFolder = Join-Path .\ "log"
$falseLimit = $XML.GroupList.Group.Count
$Time = (Get-Date).ToString("yyyy-MM-dd")

<#$foldernameで指定したディレクトリに特定のディレクトリがあるかを確認。ディレクトリがない場合は作成する。#>
 function confirm_directory($path){
    if(Test-Path $path){
        }else{
            New-Item $path -ItemType Directory
        }
}

#ログファイルを生成する
function log_file($LogString){
    $logfile =  $Time + "_" +  "setuserbalance.log"
    $logpath = Join-Path $logFolder $logfile
    $Now = Get-Date
    # Log 出力文字列に時刻を付加(YYYY/MM/DD HH:MM:SS.MMM $LogString)
    $Log = $Now.ToString("yyyy/MM/dd HH:mm:ss.fff") + " "
    $Log += $logstring
    Write-Output $Log | Out-File -FilePath $logpath -Encoding Default -append
}

#成功/失敗を記述する関数
function resultMsg1($result){
    if($result){
        return "INFO","ポイントを設定しました。"
}else{
    return "ERROR","コマンドの実行に失敗しました。config.xmlの設定内容を確認してください。"
    }
}

#ポイントをセットする関数
function setUserPoint(){
	foreach($user in $userList){
        $falseCount = 0
   		foreach($group in $XML.root.GroupList.Group){
            if($user.グループ -eq $group.Label){
                $pointList = $group.Point.Split(",")
                for ($i=0; $i -lt $pointList.Count; $i++){
                    if([string]::IsNullOrEmpty($accountList[0])){
                        if(($pointList[0] -ge 0) -and ($pointList.Length -le 1)){
                            cmd /C $servercommand set-user-account-balance $user.名前 $pointList[0] ポイント追加処理
                            $result = echo $?
                            $info,$massage = resultMsg1($result)
                            log_file($info,$user.名前,$group.Label,"ビルトインアカウント",$pointList[0],$massage)
                        }else{
                            log_file("ERROR",$user.名前,$group.Label,"config.xml -> Pointタグに不正な値が検出されました。処理を中断します。設定を確認してください。")
                            exit
                        }
                    }else{
                        if($pointList[$i] -ge 0){
                            cmd /C $servercommand set-user-account-balance $user.名前 $pointList[$i] ポイント追加処理 $accountList[$i]
                            $result = echo $?
                            $info,$massage = resultMsg1($result)
                            log_file($info,$user.名前,$group.Label,$accountList[$i],$pointList[$i],$massage)
                        }else{
                            log_file("INFO",$user.名前,$group.Label,"config.xml -> Pointタグの",$accountList[$i],"部分に値が入力されていないため、処理をスキップします。")
                        }
                    }
                 }
             }else{
                $falseCount += 1
                if($falseCount -eq $falseLimit){
                    log_file("ERROR",$user.名前,"一致するグループがありません")
                }
            }
        }
    }
}

#logフォルダの作成
confirm_directory($logFolder)
#処理開始
log_file("<Start>")
$pslogfile =  $Time + "_" +  "powershell.log"
$pslogpath = Join-Path $logFolder $pslogfile
Start-Transcript $pslogpath -Append
#ポイント設定処理
setUserPoint
#処理終了
log_file("<End>")
Stop-Transcript
