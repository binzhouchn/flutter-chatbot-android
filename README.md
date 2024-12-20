# chatbot android14.0下编译打包教程(macbook电脑操作为例)

## 1.安装android studio（AS）并配置sdk（以下这个国内网站比较全）

https://www.androiddevtools.cn/


[settings->Languages&Frameworks->Android SDK]<br>
Android SDK Location: /Users/zhoubin/Library/Android/sdk
SDK Platforms：勾选Android14.0("UpsideDownCake")--API Level 34
SDK Tools:勾选NDK，CMake，Android Emulator, Android SDK Platform-Tools

然后在.zshrc中加入环境变量export ANDROID_HOME=/Users/zhoubin/Library/Android/sdk;export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

OK环境搞定！

## 安装flutter

https://flutter.dev

```shell
unzip ~/Downloads/flutter_macos_arm64_3.27.1-stable.zip -d ~/development/
```

然后在.zshrc中加入环境变量export PATH=$HOME/development/flutter/bin:$PATH


## 3.解决Gradle找不到签名文件（keystore文件）

3.1 flutter-chatbot-android/android/gradle.properties文件中增加以下几行<br>
```shell
RELEASE_STORE_FILE=/Users/zhoubin/android_signed_key/key0.jks
RELEASE_STORE_PASSWORD=1111
RELEASE_KEY_ALIAS=key0
RELEASE_KEY_PASSWORD=1111
```

3.2 flutter-chatbot-android/android/app/build.gradle文件中修改以下几行<br>
```shell
signingConfigs {
        release {
            keyAlias RELEASE_KEY_ALIAS
            keyPassword RELEASE_KEY_PASSWORD
            storePassword RELEASE_STORE_PASSWORD
            storeFile file(RELEASE_STORE_FILE)
        }
    }
```

## 4.编译

打开terminial->cd /Users/zhoubin/AndroidProjects/flutter-chatbot-android<br>

```shell
flutter clean
flutter pub get
flutter build apk --release
```


## 5.安装

上传网盘然后点击下载安装即可食用




