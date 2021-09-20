# CielToonTest
卡通渲染测试

### 罪恶装备-经典实现方案

![](Img/test.png)

### 脸部法线修正

一、调整顶点法线实现（GGX使用的方案）

- 眼下三角区需要布置特殊排线，否则法线的变化频度不够。
- 调整法线受到排线限制，修改时自由度低。
- 修改过的法线一旦改模会丢失。

二、使用法线图（[[SP]Normal Convert Shader](https://note.com/sfna32121/n/n8d46090005d1?tdsourcetag=s_pctim_aiomsg)）

- 物体空间法线贴图，顶点变更不会影响光照分布。
- 需要光照随表情改变，可以增加一张脸部法线图做插值，自由度和可控性更好。

