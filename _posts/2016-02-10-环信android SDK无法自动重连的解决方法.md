---
layout: post
category: Android
title: 环信android SDK无法自动重连的解决方法
---

环信在第一次使用时需要执行登录的操作，之后执行连接操作，这样就可以使用其相关功能了。如果设置了自动登录，那么下次app启动的时候，环信将自动登录，然后自动连接。在环信的android SDK中，有提供登录和登出的api调用，但是没有提供连接和断开连接的api调用。环信表示SDK内部会做好相应处理，但是实际测试结果看是不理想的。在android上，按home键把应用程序退居后台10min以上，如果应用没被杀掉，再次进入应用的时候，环信是不会执行连接操作的，导致这时收不到环信推送的信息，需要杀掉应用重启才行。通过环信的log信息看出，在10min内环信不断请求连接，但是由于在后台，这些请求就被忽略了，之后达到最大请求次数后就不再请求了。目前想到的解决方案是，在应用程序进入前台后，手动执行一次登出再登录，登录的时候环信将再次重新连接。

<!-- more -->

主要的重连代码如下，在需要检查的时候调用，我这里是在进入MainActivity的时候调用。

``` java
public void reConnectIfNeed() {
    if (EMChatManager.getInstance().isConnected() || mIsConnecting) {
        return;
    }
    Accounts accounts = DataBaseHelper.getInstance().getAccounts();
    if (accounts == null || TextUtils.isEmpty(accounts.getServerId())) {
        return;
    }
    mIsConnecting = true;

    final String id = accounts.getServerId();
    EMChatManager.getInstance().logout(new EMCallBack() {

        @Override
        public void onSuccess() {
            EMChatManager.getInstance().login(id, MD5.a(id), new EMCallBack() {

                @Override
                public void onSuccess() {
                    EMChat.getInstance().setAppInited();
                    mIsConnecting = false;
                }

                @Override
                public void onError(int i, String s) {
                    mIsConnecting = false;
                }

                @Override
                public void onProgress(int i, String s) {
                    // NOOP
                }
            });
        }

        @Override
        public void onError(int code, String message) {
            mIsConnecting = false;
        }

        @Override
        public void onProgress(int progress, String status) {
            // NOOP
        }
    });
}
```

