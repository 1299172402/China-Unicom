> 中国联通APP登录 签到 金币 任务 解流量封顶    [联通用户TG交流群](https://t.me/HiCnUnicom)  
新增使用github自动运行，无需自己的服务器
## 使用方法

### 1.Fork 本仓库

### 2.添加secret
进入仓库后点击 `Settings`，右侧栏点击 `Secrets`，点击 `New secret`。分别添加 `HAOMA`、`MM` 和 `APPID` 的值，对应为你的 `要签到的手机号码`、`手机号码的服务密码` 和 `联通app抓包的appd值`。
其中 `APPID` 为联通app抓包的appid值，最好自己抓包，不会抓包就默认填 `247b001385de5cc6ce11731ba1b15835313d489d604e58280e455a6c91e5058651acfb0f0b77029c2372659c319e02645b54c0acc367e692ab24a546b83c302d`  <不保证这个appid能用，所以最好自己抓包，如果运行登录失败大概率就是appid不对或者失效>  
以下获取appid方法由群友提供：不会抓包的就去手机文件管理器，目录路径为 `Unicom/appid` ，打开复制就行了。

有多个手机号码则可以自己修改仓库文件 `.github/workflows/签到.yml` 中的每个号码的
`${{ secrets.HAOMA }}`为`${{ secrets.HAOMA2 }}`、`${{ secrets.HAOMA3 }}`等等，密码同理为`${{ secrets.MM }}`、`${{ secrets.MM2 }}`
同时也需要添加Secrets变量`HAOMA2`、`HAOMA3`、`MM2`等等。

运行开始时间也可以自己修改`.github/workflows/签到.yml`文件中`- cron: 05 23 * * *`，你想运行的北京时间减8就行了。05代表5分，23代表23时，就是0时区23：05的意思。

**PS**：我自己是7个号码签到，所以.github/workflows/签到.yml文件里面有“Run 号码1-7” 7个项目，你们可以根据自己需求自由复制或者删除，否则Actions会显示失败。

## 各版本使用教程  
> [**CnUnicom.sh**](https://github.com/mixool/HiCnUnicom/blob/master/tutorial/CnUnicom_sh_readme.md)  
> [**UnicomGetCoin.py**](https://github.com/mixool/HiCnUnicom/blob/master/tutorial/UnicomAutoGetCoin_py_readme.md)  
  
