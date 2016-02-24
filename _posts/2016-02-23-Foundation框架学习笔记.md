---
layout: post
category: iOS
title: Foundation框架学习笔记
---

学习iOS开发前的Foundation框架基础学习笔记。

<!-- more -->

使用NSArray时，初始化数组添加的最后一个nil表示数组终结，不计入数组的count。如果往NSArray中加入对象的时候，NSArray会自动retain一次对象，当数组释放的时候会自动释放其中的对象，不需要我们手动进行内存管理。

``` oc
char *type = @encode(Date) // 根据类型生成类型名称，这里Date是一个结构体
```

NSNull的作用在于要在数组添加一个空数据时不能用nil，而要用NSNull。如果是解析json到dictionary那么如果json中有null，这是不会解析成NSNull或者nil，而是直接就不存在该key-value。

NSClassFromString(@"Person")这是OC语法中的反射使用方法。


