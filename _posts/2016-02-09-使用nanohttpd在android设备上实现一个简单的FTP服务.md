---
layout: post
category: Android
title: 使用nanohttpd在android设备上实现一个简单的FTP服务
---

最近接手一个带行车记录仪的hud项目，需要实现在通过局域网下，通过ios或者android的app端能够观看、保存、删除hud设备上录制的视频文件的功能。其实简单来说就是在hud端实现一个简单的FTP服务，路劲指向视频的保存路径，并在网页上提供下载和删除的按钮。

<!-- more -->

这里我们使用[nanohttpd](https://github.com/NanoHttpd/nanohttpd)来实现这个功能。简单的示例代码如下。

``` java
public class MyApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();
        HttpServer httpServer = new HttpServer(8080);
        try {
            httpServer.start();
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }
}
```

``` java
public class HttpServer extends NanoHTTPD {

    public HttpServer(int port) {
        super(port);
    }

    @Override
    public Response serve(IHTTPSession session) {
        File folder = ...; // 视频录制的文件夹
        if (!folder.exists() || !folder.isDirectory()) {
            throw new NotFoundException("Cannot find target folder in server");
        }
        processBrowse(folder);
    }

    private Response processBrowse(File folder) {
        // 这里使用了apache模版类库velocity，遍历folder下的视频文件后生成html直接返回
        // 使用ajax进行删除操作的反向控制和刷新
        return TemplateFactory.getBrowseFolderHtml(folder);
    }
}
```

