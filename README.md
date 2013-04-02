# coffee-stack

**让Node.js输出堆栈时显示对应的Coffee源码位置！**

show coffee source location in node.js' error stack!

## Introduction

[CoffeeScript](CoffeeScript)从1.6版本开始支持SourceMap，运行`coffee main.coffee`时，错误的堆栈会显示对应coffee的代码位置。

	D:\project\github\coffee-stack\test\coffee>coffee test.coffee
	Error: D:\project\github\coffee-stack\test\coffee\test.coffee
	  at TestClass.innerError (D:\project\github\coffee-stack\test\coffee\test.coffee:5:15, <js>:8:13)
	  at Object.exports.run (D:\project\github\coffee-stack\test\coffee\test.coffee:19:7, <js>:36:11)
	  at _main (D:\project\github\coffee-stack\test\coffee\test.coffee:27:3, <js>:53:20)
	  at Object.<anonymous> (D:\project\github\coffee-stack\test\coffee\test.coffee:30:3, <js>:57:5)
	  at Object.<anonymous> (D:\project\github\coffee-stack\test\coffee\test.coffee:60:4)
	  at Module._compile (module.js:449:26)

由于我手上的Node.js项目基本上都是用CoffeeScript开发，但是只部署.js文件，正式环境下不安装coffeescript，于是这个SourceMap在正式环境下几乎毫无意义。我需要的，是在编译时指定-m参数生成.map文件后，把.js和.map文件一起部署到正式环境，使用`node main.js`的方式运行，出错提示堆栈信息时，把coffee对应的位置也打印出来。

于是，我分析了[CoffeeScript@1.6.2](1.6.2)的SourceMap的代码后，做了这个项目，效果如下：

	D:\project\github\coffee-stack\test\js>node test.js
	Error: D:\project\github\coffee-stack\test\js\test.js
	  at TestClass.innerError (D:\project\github\coffee-stack\test\js\test.js:11:13, <coffee>:4:3)
	  at Object.run (D:\project\github\coffee-stack\test\js\test.js:39:11, <coffee>:18:5)
	  at _main (D:\project\github\coffee-stack\test\js\test.js:56:20, <coffee>:26:3)
	  at Object.<anonymous> (D:\project\github\coffee-stack\test\js\test.js:60:5, <coffee>:29:4)
	  at Object.<anonymous> (D:\project\github\coffee-stack\test\js\test.js:63:4, <coffee>:1:1)
	  at Module._compile (module.js:449:26)
	  at Object..js (module.js:467:10)
	  at Module.load (module.js:356:32)
	  at Function._load (module.js:312:12)
	  at Module.runMain (module.js:492:10)
	  at process._tickCallback (node.js:244:9)
	

## Setup

	npm install git://github.com/neutra/coffee-stack.git

## Usage

编译.coffee时增加`--map`参数，将.map文件跟.js文件放在一起:

	coffee -cm -o js coffee

在入口将根目录路径传入即可:

	require('coffee-stack').patch(__dirname); // pass root directory


## Example

see [test/js/test.js](https://github.com/neutra/coffee-stack/blob/master/test/js/test.js)

## More

校对结果时发现，coffee的行号有些时候并不准确，原因尚不清楚。

在分析[CoffeeScript@1.6.2](1.6.2)代码时，发现作者后来对SourceMap的代码进行了重构，master上的sourcemap代码使用了.litcoffee格式，并添加了大量的注释，但依旧没有实现loadV3SourceMap方法。由于这个项目并不依赖CoffeeScript的代码，只是加载编译时产生的.map文件，所以理论上，即使今后SourceMap的代码有改动，此代码仍可照常使用。




[CoffeeScript]: http://coffeescript.org/  "CoffeeScript"
[1.6.2]: https://github.com/jashkenas/coffee-script/tree/1.6.2  "CoffeeScript@1.6.2"
