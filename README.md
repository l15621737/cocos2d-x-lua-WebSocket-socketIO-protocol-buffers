# cocos2d-x-lua-WebSocket-socketIO-protocol-buffers
cocos2d-x lua WebSocket socketIO protocol buffers
cocos2d-x lua 使用 websocket , PB解决方案（参考云风pbc）


前言：之前的游戏项目使用 WebSocket + SocketIO + Protocol Buffers，前端使用 js开发。现在要开发一款新的游戏使用lua，同时考虑到js端与lua端后端都要兼容只能按照之前的框架来，所以需要lua前端重新寻找支持这套方案的lua解决方法。当时js使用了 socket.io.min.js 这个库来实现socketIO，同时 google有专门针对js的库来操作PB的数据。总的来说非常容易。而现在我们的新游戏要用lua的了。查了一下相关的资料比较少，只能自己亲自来做了。总的来说有一下三个问题需要解决：

一、SocketIO：不了解的可以查询一下 socketIO具体是什么东西，这里我们前端自己去解析就好，并不复杂。需要注意的是收发的信息是每条为两次，第一次是字符串协议字段，第二次为二进制数据。先451- ....... 文本，再二进制4+二进制内容。既收到的信息一次为两条第一条是字符格式"451-["heart_res",{"_placeholder":true,"num":0}]"，第二条才是二进制   ????-�???�"数据需要我们分别解析。 同时451是一个固定的格式。详细见我的解析代码。

二、Websocket：使用cocos2d-x自带的Websocket但是有需要修改的地方

（1）接收问题：cocos2d-x lua 会自动将二进制数据转换为table（不知道为什么要做这个SB的操作）。屏蔽数据流转为table的代码 在LuaWebSocket.cpp中onMessage 

（2）发送问题：由于socketIO的要求。收发数据都必须先发送字符串的 “先451- ....... 文本，再二进制4+二进制内容”。而cocos lua只能按字符串发送。所以需要修改LuaWebSocket.cpp中的发送代码，发送不同的内容调用不同的方法：

三、protocol buffers：采用云风pbc 。使用方式详见这边文章：https://www.cnblogs.com/chevin/p/6001872.html。个人觉得云风这个pbc写的很牛逼，同时根据实际的开发要求来看也有值得修改的地方：（1）返回的内容不会完全展开而是需要使用“.”去更深度访问，而本身打印出来的数据却看不到这些字段（估计这样做是为了更高的解析效率，但实际我们收到后端的数据是要完整打印出来查看的，所以这点上需要修改） （2）访问一个空的字段回报错，实际我们是希望访问空直接返回nil。
我已经对云风pbc的代码做了修改。如果需要的话请用我提供的代码进行替换，如果不需要的话。请使用上面文章下载的代码。
