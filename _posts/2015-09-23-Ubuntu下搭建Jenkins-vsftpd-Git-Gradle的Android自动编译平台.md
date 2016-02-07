---
layout: post
category: team
title: Ubuntu下搭建Jenkins+vsftpd+Git+Gradle的Android自动编译平台
---

在实际软件工作中，涉及研发、测试、产品经理等多个职位的配合。时常会出现测试人员向研发要测试软件，产品经理想要体验软件向研发要最新软件，产品临时发样向研发人员要发样软件，如此之类的需求时常打断研发的工作。有时开发的过程中，测试人员发现了一个bug，进一步测试发现之前的代码中也存在这个bug，之前发出去的软件也存在这个bug，然后就开始了痛苦的代码回溯及编译APK验证测试。

<!-- more -->

因此需要一个自动软件编译平台来解决以上问题，这个平台每天凌晨自动编译一版本APK，所有需要APK的人员都可以登上FTP服务器获取，无需打断研发的工作。当回溯bug时只需要测试每天编译出来的APK就能很快定位到是哪次代码提交导致的问题。本文使用Jenkins自动编译平台，vsftpd搭建FTP服务器，Git作为代码管理工具，使用Gradle编译APK，详细软件版本信息如下：  

>
ubuntu：14.04  
vsftpd：3.0.2  
java：1.8.0_60  
jenkins：1.609.3

###一、安装配置Jenkins

从[官网](https://jenkins-ci.org)下载Jenkins的deb安装包，虽然也能从命令行安装，但deb的安装方式更加简便。需要注意的是，有时首页的下载按钮会显示不出来，所以建议翻墙访问。安装完成后建议重启。然后打开浏览器：http://127.0.0.1:8080/ ，若能正常显示jenkins界面，则说明安装成功  

点击右侧"系统管理"后选择"管理插件"，再选择"可选插件"选项卡，此时会列出所有可以安装的插件。在顶部的过滤对话框输入GIT plugin，选择GIT plugin进行安装。除了安装GIT plugin，可能还会自动安装其他关联的插件。建议先翻墙再进行此步操作，否则可能加载不出插件列表  

安装jdk，假设安装到的路径为/usr/lib/java/jdk1.8.0_60，然后设置JAVA_HOME等环境变量，网上有很多教程，不再赘述。点击右侧"系统管理"后选择"系统设置"，点击“JDK安装”下的新增JDk。不要勾选自动安装，填写“别名”和“JAVA_HOME”，“别名”可以随便写，“JAVA_HOME”写/usr/lib/java/jdk1.8.0_60。点击底部保存，保存所有修改  

###二、为Jenkins添加ssh私钥

jenkins在安装完成后，默认会创建一个jenkins账户，其根目录为/var/lib/jenkins。若在jenkins上使用git拉代码，则需要添加相应ssh私钥。先准备好可以在git上拉代码的私钥id\_rsa。在/var/lib/jenkins目录下新建.ssh文件夹。将id\_rsa复制到/var/lib/jenkins/.ssh。这一步非常重要，使用以下命令更改id\_rsa的权限。修改完成后，id_rsa的权限为：  
\- r w - - - - - - - 1 jenkins jenkins /var/lib/jenkins/.ssh/id\_rsa

``` shell
sudo chmod 600 id_rsa
sudo chgrp jenkins id_rsa
sudo chown jenkins id_rsa
```

###三、下载配置Android SDK Tools

从Android官网下载SDK Tools，不需要下载整个Android Studio。下载完成后解压放置到/usr/local/android-sdk目录。启动SDK Tools，下载相应的android版本和编译工具，网上有很多教程，不再赘述。添加ANDROID\_HOME环境变量，这个环境变量是jenkins通过gradle编译apk时需要用到的，考虑到ubuntu上的其他用户也要用到此环境变量，故添加为全局环境变量，在/etc/environment文件末尾加上export ANDROID\_HOME=/usr/local/android-sdk。完成之后重新系统让环境变量生效

###四、创建配置一个Jenkins编译项目

打开浏览器：http://127.0.0.1:8080/ ，选择“创建一个新任务”，再选择“构建一个自由风格的软件项目”并填写“Item名称”，这里给一个参考格式：项目名-nightly。点击OK后进入配置页面。选择配置页面的“源码管理”下的Git，在Repository URL后填写代码的git地址，若jenkins无法通过此地址获取代码，那么稍等几秒界面上就会有红色的错误提示。Branches to build是用来指定要编译的分支名，默认是指向master的。点击“构建”下的“增加构建步骤”并选择Execute shell，在Command后面写gradle的编译命令及其他的shell脚本。此时先不写gradle的编译脚本，只写：echo hello!!!，因为jenkins执行自动编译是有超时时间的，在使用gradle编译apk时会先下载对应版本的gradle，在国内的下载速度是很慢的，经常会超过jenkins的编译超时时间，故需要单独初始化下载gradle。点击页面底部的保存按钮，完成配置。点击左侧的立即构建，开始第一次自动编译，点击“#1”进入详细页面，点击“Console Output”，查看实时的编译输出。当最后输出Finished: SUCCESS说明编译成功。此时jenkins已经将对应的代码拉到指定的目录了

###五、初始化下载gradle

jenkins的所有自动编译项目都在/var/lib/jenkins/jobs目录下，假设此时的项目名称为test-nightly，那么源码所在的目录为/var/lib/jenkins/jobs/test-nightly/workspace。运行以下命令，初始化下载项目对应的gradle，之所以在这里执行，是因为既可以不受jenkins编译超市时间的限制，又可以看到实时的下载进度，建议翻墙后再执行以下操作，以免出现无法下载的情况。当执行完以下命令，出现BUILD SUCCESSFUL时说明操作成功

``` shell
sudo su jenkins # 切换到jenkins账户，这里会要求输入密码，输入的是你当前帐户的密码，而不是jenkins账户的密码
cd /var/lib/jenkins/jobs/test_night/workspace # 进入源码目录
./gradlew clean # 开始初始化下载gradle
```

###六、完善Jenkins自动编译配置

打开浏览器：http://127.0.0.1:8080/ ，进入项目test-nightly的配置界面，勾选“构建触发器”下的Build periodically，此项是用来指定jenkins每日自动构建的时间点的。比如指定需要在每天凌晨5点到6点之间的随机事件点执行一次自动编译，那么填写：H 5 \* \* \*，这里有五个参数，参数之间通过空格分割。
> 第一个参数代表分钟，取值范围：0~59  
> 第二个参数代表的是小时，取值范围：0~23  
> 第三个参数代表的是天，取值范围：1~31  
> 第四个参数代表的是月，取值范围：1~12  
> 第五个参数代表的是星期，取值范围：0~7，0和7都是表示星期天  
> \*代表任意值，H代表该参数值域内的任意值

在Execute shell的Command处将之前的echo hello!!!改为以下脚本。保存后执行立即构建，出现BUILD SUCCESSFUL时说明操作成功。此时/var/lib/jenkins/build_release目录下已经有相应的子目录和apk了  

``` shell
APP_NAME=test-nightlyDATE=`date "+%y-%m-%d"`bash $WORKSPACE/gradlew clean build # 编译apkDIR=~/build_release/${APP_NAME}/$DATEif [ ! -d $DIR ]; thenmkdir -p $DIRfimv $WORKSPACE/app/build/outputs/apk/app-release.apk $DIR/${APP_NAME}-${BUILD_NUMBER}.apk
```

###七、搭建FTP服务器

搭建FTP服务器使用的是vsftpd，运行以下命令安装vsftpd  
 
``` shell
sudo apt-get install vsftpd
```
 
运行以下命令判断vsftpd是否安装成功并且已经启动  

``` shell
sudo service vsftpd restart
```

新建文件/etc/vsftpd.chroot_list和/etc/vsftpd.user_list，分别写上支持ftp登陆的账户名，比如我的ubuntu系统用户名是zhenglingxiao，就分别填写zhenglingxiao。这两个文件支持填写多个用户名，每行一个用户名，所以也可以建立专用的ftp用户。vsftpd的配置文件是/etc/vsftpd.conf，在文件末尾加上如下配置信息

``` shell
# 设置FTP登陆后转向的文件目录，这个目录是我们之前配置的jenkins编译后放置apk的目录
local_root=/var/lib/jenkins/build_release/
# 设置只有/etc/vsftpd.user_list中的用户才有登录FTP的权限userlist_enable=yesuserlist_deny=NOuserlist_file=/etc/vsftpd.user_list
# 设置/etc/vsftpd.chroot_list中的用户在登陆FTP后只能查看本目录下的子目录和文件chroot_list_enable=YESchroot_list_file=/etc/vsftpd.chroot_list
```

在浏览器输入：ftp://服务器IP地址，会跳出登录窗口，登录后就能看到jenkins编译出来的apk了


