#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin && export PATH
# Usage:
## wget --no-check-certificate https://raw.githubusercontent.com/mixool/HiCnUnicom/master/CnUnicom.sh && chmod +x CnUnicom.sh && bash CnUnicom.sh membercenter 13800008888@112233 18388880000@123456
### bash <(curl -s https://raw.githubusercontent.com/mixool/HiCnUnicom/master/CnUnicom.sh) membercenter 13800008888@112233 18388880000@123456

# 传入参数格式，支持多账号，手机号@密码必需：13800008888@112233 18388880000@123456
[[ $# != 0 ]] && all_parameter=($(echo $@)) || { echo 'Err  !!! Useage: bash this_script.sh membercenter 13800008888@112233 18388880000@123456'; exit 1; }
all_username_password=($(echo ${all_parameter[*]} | grep -oE "[0-9]{11}@[0-9]{6}"| sort -u | tr "\n" " "))

# 登录失败尝试修改以下这个appId的值为抓包获取的登录过的联通app,也可使用传入参数 appId@*************
appId=247b001385de5cc6ce11731ba1b15835313d489d604e58280e455a6c91e5058651acfb0f0b77029c2372659c319e02645b54c0acc367e692ab24a546b83c302d
echo ${all_parameter[*]} | grep -qE "appId@[a-z0-9]+" && appId=$(echo ${all_parameter[*]} | grep -oE "appId@[a-z0-9]+" | cut -f2 -d@)

# deviceId: 随机IMEI,也可使用传入参数 deviceId@*************
deviceId=$(shuf -i 123456789012345-987654321012345 -n 1)
echo ${all_parameter[*]} | grep -qE "deviceId@[0-9]+" && deviceId=$(echo ${all_parameter[*]} | grep -oE "deviceId@[0-9]+" | cut -f2 -d@)

#####
## 流量激活功能需要传入参数,中间d表示每天,w表示每周一,m代表每月第二天,格式： liulactive@d@ff80808166c5ee6701676ce21fd14716
## 如仅需要部分号码激活流量包时使用参数格式：liulactive@d@ff80808166c5ee6701676ce21fd14716@13012341234-18812341234
## 1GB日包：          ff80808166c5ee6701676ce21fd14716
## 2GB日包:           21010621565413402
## 5GB日包:           21010621461012371
## 10GB日包:          21010621253114290
## 4GB流量七日包:     20080615550312483
## 100MB全国流量月包: ff80808165afd2960165d1eb75424667
## 300MB全国流量月包：ff80808165afd2960165d1e93423464a
## 500MB全国流量月包: ff80808165afd2960165cdbf4a950c1c
## 1GB全国流量月包：  ff80808165afd2960165cdbc92470bef
#####

# 使用Github Action运行时需要传入参数来修改工作路径: githubaction
workdirbase="/var/log/CnUnicom"
echo ${all_parameter[*]} | grep -qE "githubaction" && workdirbase="$(pwd)/CnUnicom"

# 联通APP版本
unicom_version=8.0100

# UA
UA="Mozilla/5.0 (Linux; Android 6.0.1; oneplus a5010 Build/V417IR; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/52.0.2743.100 Mobile Safari/537.36; unicom{version:android@$unicom_version,desmobile:$username};devicetype{deviceBrand:Oneplus,deviceModel:oneplus a5010}"

# alias curl
alias curl='curl -m 10'

################################################################
function rsaencrypt() {
    cat > $workdir/rsa_public.key <<-EOF
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDc+CZK9bBA9IU+gZUOc6
FUGu7yO9WpTNB0PzmgFBh96Mg1WrovD1oqZ+eIF4LjvxKXGOdI79JRdve9
NPhQo07+uqGQgE4imwNnRx7PFtCRryiIEcUoavuNtuRVoBAm6qdB0Srctg
aqGfLgKvZHOnwTjyNqjBUxzMeQlEC2czEMSwIDAQAB
-----END PUBLIC KEY-----
EOF

    crypt_username=$(echo -n $username | openssl rsautl -encrypt -inkey $workdir/rsa_public.key -pubin -out >(base64 | tr "\n" " " | sed s/[[:space:]]//g))
    crypt_password=$(echo -n $password | openssl rsautl -encrypt -inkey $workdir/rsa_public.key -pubin -out >(base64 | tr "\n" " " | sed s/[[:space:]]//g))
}

function urlencode() {
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf "$c" | xxd -p -c1 | while read x;do printf "%%%s" "$x";done
        esac
    done
}

function userlogin() {
    rsaencrypt
    cat > $workdir/signdata <<-EOF
isRemberPwd=true
&deviceId=$deviceId
&password=$(urlencode $crypt_password)
&simCount=0
&netWay=Wifi
&mobile=$(urlencode $crypt_username)
&yw_code=
&timestamp=$(date +%Y%m%d%H%M%S)
&appId=$appId
&keyVersion=1
&deviceBrand=Oneplus
&pip=10.0.$(shuf -i 1-255 -n 1).$(shuf -i 1-255 -n 1)
&provinceChanel=general
&version=android%40$unicom_version
&deviceModel=oneplus%20a5010
&deviceOS=android6.0.1
&deviceCode=$deviceId
EOF

    # cookie登录
    curl -X POST -sA "$UA" -b $workdir/cookie -c $workdir/cookie "https://m.client.10010.com/mobileService/customer/query/getMyUnicomDateTotle.htm?yw_code=&mobile=$username&version=android%40$unicom_version" | grep -oE "infoDetail" >/dev/null && status=0 || status=1
    [[ $status == 0 ]] && echo && echo $(date) cookies登录${username:0:2}******${username:8}成功
    
    # 账号密码登录
    if [[ $status == 1 ]]; then
        rm -rf $workdir/cookie*
        curl -X POST -sA "$UA" -c $workdir/cookie "https://m.client.10010.com/mobileService/logout.htm?&desmobile=$username&version=android%40$unicom_version" >/dev/null
        curl -sA "$UA" -b $workdir/cookie -c $workdir/cookie -d @$workdir/signdata "https://m.client.10010.com/mobileService/login.htm" >/dev/null
        token=$(cat $workdir/cookie | grep -E "a_token" | awk  '{print $7}')
        [[ "$token" = "" ]] && echo && echo $(date) ${username:0:2}******${username:8} Login Failed. && rm -rf $workdir && return 1
        echo && echo $(date) 密码登录${username:0:2}******${username:8}成功
    fi
}

function membercenter() {
    echo ${all_parameter[*]} | grep -qE "membercenter" || return 0
    echo; echo starting membercenter...
    
    # 获取文章和评论生成数组数据
    NewsListId=($(curl -X POST -sA "$UA" -b $workdir/cookie --data "pageNum=1&pageSize=10&reqChannel=00" https://m.client.10010.com/commentSystem/getNewsList | grep -oE "id\":\"[^\"]*" | awk -F[\"] '{print $NF}' | tr "\n" " "))
    comtId=($(curl -X POST -sA "$UA" -b $workdir/cookie --data "id=${NewsListId[0]}&pageSize=10&pageNum=1&reqChannel=quickNews" -e "https://img.client.10010.com/kuaibao/detail.html?pageFrom=newsList&id=${NewsListId[0]}" https://m.client.10010.com/commentSystem/getCommentList | grep -oE "id\":\"[^\"]*" | awk -F[\"] '{print $NF}' | tr "\n" " "))
    nickId=($(curl -X POST -sA "$UA" -b $workdir/cookie --data "id=${NewsListId[0]}&pageSize=10&pageNum=1&reqChannel=quickNews" -e "https://img.client.10010.com/kuaibao/detail.html?pageFrom=newsList&id=${NewsListId[0]}" https://m.client.10010.com/commentSystem/getCommentList | grep -oE "nickName\":\"[^\"]*" | awk -F[\"] '{print $NF}' | tr "\n" " "))
    Referer="https://img.client.10010.com/kuaibao/detail.html?pageFrom=${NewsListId[0]}"
   
    # 评论点赞后取消点赞
    for ((i = 0; i < ${#comtId[*]}; i++)); do
        curl -X POST -sA "$UA" -b $workdir/cookie --data "pointChannel=02&pointType=02&reqChannel=quickNews&reqId=${comtId[i]}&praisedMobile=${nickId[i]}&newsId=${NewsListId[0]}" -e "$Referer" https://m.client.10010.com/commentSystem/csPraise
        curl -X POST -sA "$UA" -b $workdir/cookie --data "pointChannel=02&pointType=01&reqChannel=quickNews&reqId=${comtId[i]}&praisedMobile=${nickId[i]}&newsId=${NewsListId[0]}" -e "$Referer" https://m.client.10010.com/commentSystem/csPraise | grep -oE "growScore\":\"0\"" >/dev/null && break
    done
    
    # 文章点赞后取消点赞
    for ((i = 0; i <= ${#NewsListId[*]}; i++)); do
        curl -X POST -sA "$UA" -b $workdir/cookie --data "pointChannel=01&pointType=02&reqChannel=quickNews&reqId=${NewsListId[i]}" https://m.client.10010.com/commentSystem/csPraise
        curl -X POST -sA "$UA" -b $workdir/cookie --data "pointChannel=01&pointType=01&reqChannel=quickNews&reqId=${NewsListId[i]}" https://m.client.10010.com/commentSystem/csPraise | grep -oE "growScore\":\"0\"" >/dev/null && break
    done
    
    # 文章评论后删除评论
    newsTitle="$(curl -X POST -sA "$UA" -b $workdir/cookie --data "newsId=${NewsListId[1]}&reqChannel=quickNews&isClientSide=0&pageFrom=newsList" -e "$Referer" https://m.client.10010.com/commentSystem/getNewsDetails | grep -oE "mainTitle\":\"[^\"]*" | awk -F[\"] '{print $NF}')"
    subTitle="$(curl -X POST -sA "$UA" -b $workdir/cookie --data "newsId=${NewsListId[1]}&reqChannel=quickNews&isClientSide=0&pageFrom=newsList" -e "$Referer" https://m.client.10010.com/commentSystem/getNewsDetails | grep -oE "subTitle\":\"[^\"]*" | awk -F[\"] '{print $NF}')"
    for ((i = 0; i <= 5; i++)); do
        data="id=${NewsListId[1]}&newsTitle=$(urlencode $newsTitle)&commentContent=$RANDOM&upLoadImgName=&reqChannel=quickNews&subTitle=$(urlencode $subTitle)&belongPro=098"
        mycomtId="$(curl -X POST -sA "$UA" -b $workdir/cookie --data "$data" -e "$Referer" https://m.client.10010.com/commentSystem/saveComment | grep -oE "id\":\"[^\"]*" | awk -F[\"] '{print $NF}')"
        curl -X POST -sA "$UA" -b $workdir/cookie --data "type=01&reqId=$mycomtId&reqChannel=quickNews" -e "$Referer" https://m.client.10010.com/commentSystem/delDynamic
    done
    
    # 每月一次账单查询
    if [[ "$(date "+%d")" == "01" ]]; then
        curl -sLA "$UA" -b $workdir/cookie -c $workdir/cookie.HistoryBill --data "yw_code=&desmobile=$username&version=android@$unicom_version" "https://m.client.10010.com/mobileService/common/skip/queryHistoryBill.htm?mobile_c_from=home" >/dev/null
        curl -sLA "$UA" -b $workdir/cookie.HistoryBill --data "operateType=0&bizCode=1000210003&height=889&width=480" "https://m.client.10010.com/mobileService/query/querySmartBizNew.htm?" >/dev/null
        curl -sLA "$UA" -b $workdir/cookie.HistoryBill --data "systemCode=CLIENT&transId=&userNumber=$username&taskCode=TA52554375&finishTime=$(date +%Y%m%d%H%M%S)" "https://act.10010.com/signinAppH/limitTask/limitTime" >/dev/null
    fi

    # 每日一次余量查询
    curl -sLA "$UA" -b $workdir/cookie -c $workdir/cookie.LeavePackage --data "desmobile=$username&version=android@$unicom_version" "https://m.client.10010.com/mobileService/common/skip/queryLeavePackage.htm" >/dev/null
    curl -sLA "$UA" -b $workdir/cookie.LeavePackage --data "operateType=0&bizCode=1000210026&height=776&width=480" "https://m.client.10010.com/mobileService/query/querySmartBizNew.htm?" >/dev/null
    curl -sLA "$UA" -b $workdir/cookie.LeavePackage --data "type=0" "https://m.client.10010.com/mobileService/grow/marginCheck.htm"
    
    # 签到
    Referer="https://img.client.10010.com/activitys/member/index.html"
    data="yw_code=&desmobile=$username&version=android@$unicom_version"
    curl -sLA "$UA" -b $workdir/cookie -c $workdir/cookie.SigninActivity -e "$Referer" "https://act.10010.com/SigninApp/signin/querySigninActivity.htm?$data" >/dev/null
    Referer="https://act.10010.com/SigninApp/signin/querySigninActivity.htm?$data"
    curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity -e "$Referer" "https://act.10010.com/SigninApp/signin/daySign?vesion=0.$(shuf -i 1234567890123456-9876543210654321 -n 1)"
    echo
    curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity -e "$Referer" "https://act.10010.com/SigninApp/signin/todaySign"
    echo
    curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity -e "$Referer" "https://act.10010.com/SigninApp/signin/addIntegralDA"

    curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity -e "$Referer" "https://act.10010.com/SigninApp/signin/getContinuous"
    curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity -e "$Referer" "https://act.10010.com/SigninApp/signin/getIntegral"
    curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity -e "$Referer" "https://act.10010.com/SigninApp/signin/getGoldTotal"

    curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity -e "$Referer" "https://act.10010.com/SigninApp/signin/bannerAdPlayingLogo"
    
    # 三次金币抽奖， 每日最多可花费金币执行十三次
    usernumberofjsp=$(curl -sA "$UA" -b $workdir/cookie.SigninActivity https://m.client.10010.com/dailylottery/static/textdl/userLogin | grep -oE "encryptmobile=\w*" | awk -F"encryptmobile=" '{print $2}'| head -n1)
    for ((i = 1; i <= 3; i++)); do
        [[ $i -gt 3 ]] && curl -sA "$UA" -b $workdir/cookie.SigninActivity --data "goldnumber=10&banrate=10&usernumberofjsp=$usernumberofjsp" https://m.client.10010.com/dailylottery/static/doubleball/duihuan >/dev/null; sleep 1
        curl -sA "$UA" -b $workdir/cookie.SigninActivity --data "usernumberofjsp=$usernumberofjsp&flag=convert" https://m.client.10010.com/dailylottery/static/doubleball/choujiang | grep -qE "用户机会次数不足" && break
    done
    echo; echo goldTotal：$(curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity -e "$Referer" "https://act.10010.com/SigninApp/signin/getGoldTotal?vesion=0.$(shuf -i 1234567890123456-9876543210654321 -n 1)")
    
    # 积分抽奖首次免费，之后领300定向积分兑换再抽奖,最多三十次
    curl -sLA "$UA" -b $workdir/cookie "https://m.client.10010.com/welfare-mall-front/mobile/winter/getpoints/v1"
    curl -X POST -sLA "$UA" -b $workdir/cookie --data "from=$(shuf -i 12345678901-98765432101 -n 1)" "https://m.client.10010.com/welfare-mall-front/mobile/winterTwo/getIntegral/v1"
    curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity --data "usernumberofjsp=$usernumberofjsp&flag=convert" http://m.client.10010.com/dailylottery/static/integral/choujiang
    for ((i = 1; i <= 15; i++)); do
        curl -sA "$UA" -b $workdir/cookie.SigninActivity --data "goldnumber=10&banrate=30&usernumberofjsp=$usernumberofjsp" http://m.client.10010.com/dailylottery/static/integral/duihuan >/dev/null; sleep 1
        curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity --data "usernumberofjsp=$usernumberofjsp&flag=convert" http://m.client.10010.com/dailylottery/static/integral/choujiang | grep -qE "用户机会次数不足" && break
    done
    
    # 每日领100定向积分
    echo; curl -X POST -sA "$UA" -b $workdir/cookie --data "from=$(shuf -i 12345678901-98765432101 -n 1)" https://m.client.10010.com/welfare-mall-front/mobile/integral/gettheintegral/v1
    
    # 游戏签到积分 每日1积分
    curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity --data "methodType=iOSIntegralGet&gameLevel=1&deviceType=iOS" "https://m.client.10010.com/producGameApp"
    
    # 奖励积分
    echo; curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity --data "methodType=signin" https://m.client.10010.com/producGame_signin
    
    # 游戏宝箱
    curl -X POST -sA "$UA"  -b $workdir/cookie.SigninActivity -c $workdir/cookie.xybx --data "thirdUrl=https%3A%2F%2Fimg.client.10010.com%2Fshouyeyouxi%2Findex.html%23%2Fyouxibaoxiang" https://m.client.10010.com/mobileService/customer/getShareRedisInfo.htm >/dev/null
    echo; curl -X POST -sA "$UA" -b $workdir/cookie.xybx --data "methodType=reward&deviceType=Android&clientVersion=$unicom_version&isVideo=N" https://m.client.10010.com/game_box
    echo; curl -sA "$UA" -b $workdir/cookie.xybx --data "methodType=taskGetReward&taskCenterId=187&clientVersion=$unicom_version&deviceType=Android" https://m.client.10010.com/producGameTaskCenter
    echo; curl -X POST -sA "$UA" -b $workdir/cookie.xybx --data "methodType=reward&deviceType=Android&clientVersion=$unicom_version&isVideo=Y" https://m.client.10010.com/game_box
    
    # 获得流量
    for ((i = 1; i <= 3; i++)); do
        curl -X POST -sA "$UA" -b $workdir/cookie --data "stepflag=22" https://act.10010.com/SigninApp/mySignin/addFlow >/dev/null; sleep 5
        curl -X POST -sA "$UA" -b $workdir/cookie --data "stepflag=23" https://act.10010.com/SigninApp/mySignin/addFlow | grep -oE "reason\":\"01\"" >/dev/null && break
    done
    
    # info
    echo; echo membercenter accomplished.
}

function tgbotinfo() {
    # TG_BOT通知消息: 未设置相应传入参数时不执行,传入参数格式 token@*** chat_id@*** | 参考: https://github.com/LXK9301/jd_scripts/blob/master/backUp/TG_PUSH.md
    echo ${all_parameter[*]} | grep -qE "token@[a-zA-Z0-9:_-]+" && token="$(echo ${all_parameter[*]} | grep -oE "token@[a-zA-Z0-9:_-]+" | cut -f2 -d@)" || return 0
    echo ${all_parameter[*]} | grep -qE "chat_id@[0-9-]+" && chat_id="$(echo ${all_parameter[*]} | grep -oE "chat_id@[0-9-]+" | cut -f2 -d@)" || return 0
    text="$(echo -e ${username}积分通知😋'\n'总积分:${total}'\n'本月新增奖励积分:${addScore}'\n'本月将过期奖励积分:${invalidscore}'\n'本月将过期积分:${invalid}'\n'可用积分:${canUse}'\n'奖励积分:${availablescore}'\n'昨日奖励积分:${yesterdayscore} 今日奖励积分:${todayscore})"
    curl -sX POST "https://api.telegram.org/bot$token/sendMessage" -d "chat_id=$chat_id&text=$text" >/dev/null
}

function liulactive() {
    # 流量激活功能
    echo ${all_parameter[*]} | grep -qE "liulactive@[mwd]@[0-9a-z]+" || return 0
    timeparId=$(echo ${all_parameter[*]} | grep -oE "liulactive@[mwd]@[0-9a-z]+" | cut -f2 -d@)
    productId=$(echo ${all_parameter[*]} | grep -oE "liulactive@[mwd]@[0-9a-z]+" | cut -f3 -d@)
    choosenos=$(echo ${all_parameter[*]} | grep -oE "liulactive@[mwd]@[0-9a-z]+@.*" | cut -f4 -d@)
    # 依照参数m|w|d来判断是否执行
    unset liulactive_run
    [[ ${timeparId} == "m" ]] && [[ "$(date +%d)" == "02" ]] && liulactive_run=true
    [[ ${timeparId} == "w" ]] && [[ "$(date +%u)" == "1" ]]  && liulactive_run=true
    [[ ${timeparId} == "d" ]] && liulactive_run=true
    [[ "$liulactive_run" == "true" ]] || return 0
    # 依照参数choosenos来判断是否是指定号码执行,激活功能的参数全格式： liulactive@d@ff80808166c5ee6701676ce21fd14716@13012341234-13112341234
    unset liulactive_only
    [[ $choosenos != "" ]] && echo $choosenos | grep -qE "${username}" && liulactive_only=true
    [[ $choosenos == "" ]] && liulactive_only=true
    [[ "$liulactive_only" == "true" ]] || return 0
    # 激活请求
    echo; echo starting liulactive..
    curl -sA "$UA" -b $workdir/cookie -c $workdir/cookie_liulactive "https://m.client.10010.com/MyAccount/trafficController/myAccount.htm?flag=1&cUrl=https://m.client.10010.com/myPrizeForActivity/querywinninglist.htm?pageSign=1" >$workdir/liulactive.log
    liulactiveuserLogin="$(cat $workdir/liulactive.log | grep "refreshAccountTime" | grep -oE "[0-9_]+")"
    curl -sA "$UA" -b $workdir/cookie_liulactive -c $workdir/cookie_liulactive "https://m.client.10010.com/MyAccount/MyGiftBagController/refreshAccountTime.htm?userLogin=$liulactiveuserLogin&accountType=FLOW" >/dev/null
    curl -X POST -sA "$UA"  -b $workdir/cookie_liulactive -c $workdir/cookie_liulactive --data "thirdUrl=thirdUrl=https%3A%2F%2Fm.client.10010.com%2FMyAccount%2FtrafficController%2FmyAccount.htm" https://m.client.10010.com/mobileService/customer/getShareRedisInfo.htm >/dev/null
    Referer="https://m.client.10010.com/MyAccount/trafficController/myAccount.htm?flag=1&cUrl=https://m.client.10010.com/myPrizeForActivity/querywinninglist.htm?pageSign=1"
    curl -X POST -sA "$UA" -e "$Referer" -b $workdir/cookie_liulactive -c $workdir/cookie_liulactive --data "productId=$productId&userLogin=$liulactiveuserLogin&ebCount=1000000&pageFrom=4" "https://m.client.10010.com/MyAccount/exchangeDFlow/exchange.htm?userLogin=$liulactiveuserLogin" | grep -B 1 "正在为您激活"
}

function hfgoactive() {
    # 话费购活动，需传入参数 hfgoactive
    echo ${all_parameter[*]} | grep -qE "hfgoactive" || return 0
    echo; echo starting hfgoactive...
    curl -sLA "$UA" -b $workdir/cookie -c $workdir/cookie_hfgo "https://m.client.10010.com/mobileService/openPlatform/openPlatLineNew.htm?to_url=https://account.bol.wo.cn/cuuser/open/openLogin/hfgo&yw_code=&desmobile=${username}&version=android@${unicom_version}" >/dev/null
    # 抽奖,每日免费3次,签到七天获得额外3次
    ACTID="$(curl -X POST -sA "$UA" -b $workdir/cookie_hfgo --data "positionType=1" https://hfgo.wo.cn/hfgoapi/product/ad/list | grep -oE "atplottery[^?]*" | cut -f2 -d/)"
    curl -sLA "$UA" -b $workdir/cookie_hfgo -c $workdir/cookie_hfgo "https://hfgo.wo.cn/hfgoapi/cuuser/auth/autoLogin?redirectUrl=https://atp.bol.wo.cn/atplottery/${ACTID}?product=hfgo&ch=002&$(cat $workdir/cookie_hfgo | grep -oE "[^_]token.*" | sed s/[[:space:]]//g | sed "s/token/Authorization=/")" >/dev/null
    for ((i = 1; i <= 7; i++)); do
        echo
        curl -sA "$UA"  -b $workdir/cookie_hfgo "https://atp.bol.wo.cn/atpapi/act/lottery/start/v1/actPath/${ACTID}/0" >$workdir/lottery_hfgo.log
        cat $workdir/lottery_hfgo.log
        cat $workdir/lottery_hfgo.log | grep -qE "抽奖次数已用完" && break
    done
    # 签到
    echo; curl -sA "$UA"  -b $workdir/cookie_hfgo https://atp.bol.wo.cn/atpapi/act/actUserSign/everydaySign?actId=1516
}

function jifeninfo() {
    # 积分信息显示，需传入参数 jifeninfo
    echo ${all_parameter[*]} | grep -qE "jifeninfo" || return 0
    echo; echo starting jifeninfo...
    curl -X POST -sA "$UA" -b $workdir/cookie --data "reqsn=&reqtime=&cliver=&reqdata=" "https://m.client.10010.com/welfare-mall-front/mobile/show/queryUserTotalScore/v1" >$workdir/jifeninfo.log1 
    curl -X POST -sA "$UA" -b $workdir/cookie --data "reqsn=&reqtime=&cliver=&reqdata=" "https://m.client.10010.com/welfare-mall-front/mobile/show/flDetail/v1/0" >$workdir/jifeninfo.log2
    # 
    total=$(cat $workdir/jifeninfo.log1 | grep -oE "total\":[0-9]+" | grep -oE "[0-9]+")
    invalid=$(cat $workdir/jifeninfo.log1 | grep -oE "invalid\":[0-9]+" | grep -oE "[0-9]+")
    canUse=$(cat $workdir/jifeninfo.log1 | grep -oE "canUse\":[0-9]+" | grep -oE "[0-9]+")
    #
    availablescore=$(cat $workdir/jifeninfo.log2 | grep -oE "availablescore\":\"[0-9]+" | grep -oE "[0-9]+")
    invalidscore=$(cat $workdir/jifeninfo.log2 | grep -oE "invalidscore\":\"[0-9]+" | grep -oE "[0-9]+")
    addScore=$(cat $workdir/jifeninfo.log2 | grep -oE "addScore\":\"[0-9]+" | grep -oE "[0-9]+")
    # 今日奖励积分
    today="$(date +%Y-%m-%d)" && todayscore=0
    todayscorelist=($(cat $workdir/jifeninfo.log2 | grep -oE "createTime\":\"$today[^}]*" | grep -oE "books_number\":[0-9]+" | grep -oE "[0-9]+" | tr "\n" " "))
    for ((i = 0; i < ${#todayscorelist[*]}; i++)); do todayscore=$((todayscore+todayscorelist[i])); done
    # 昨日奖励积分
    yesterday="$(date -d "1 days ago" +%Y-%m-%d)" && yesterdayscore=0
    yesterdayscorelist=($(cat $workdir/jifeninfo.log2 | grep -oE "createTime\":\"$yesterday[^}]*" | grep -oE "books_number\":[0-9]+" | grep -oE "[0-9]+" | tr "\n" " "))
    for ((i = 0; i < ${#yesterdayscorelist[*]}; i++)); do yesterdayscore=$((yesterdayscore+yesterdayscorelist[i])); done
    # info
    echo 总积分:$total 本月将过期积分:$invalid 可用积分:$canUse
    echo 奖励积分:$availablescore 本月将过期奖励积分:$invalidscore 
    echo 本月新增奖励积分:$addScore 昨日奖励积分:$yesterdayscore 今日奖励积分:$todayscore
}

function main() {
    # 签到任务
    for ((u = 0; u < ${#all_username_password[*]}; u++)); do 
        sleep $(shuf -i 1-10 -n 1)
        username=${all_username_password[u]%@*} && password=${all_username_password[u]#*@}
        workdir="${workdirbase}_${username}" && [[ ! -d "$workdir" ]] && mkdir $workdir
        userlogin && userlogin_ook[u]=$(echo ${username:0:2}******${username:8}) || { userlogin_err[u]=$(echo ${username:0:2}******${username:8}); continue; }
        membercenter
        liulactive
        hfgoactive
        jifeninfo
        #rm -rf $workdir
    done
    echo; echo $(date) ${userlogin_err[*]} ${#userlogin_err[*]} 签到失败. ${userlogin_ook[*]} ${#userlogin_ook[*]} 签到完成.
    # TG通知
    tgbotinfo
}

main