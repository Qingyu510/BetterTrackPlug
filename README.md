![Screenshot](https://github.com/Qingyu510/BetterTrackPlug/blob/master/BetterTrackPlug.png)
# 这是什么?
一个记录你游戏时长的插件，一个向你显示记录游戏时长的应用程序。

# 这个“Better”怎么说?
- 由于它被重写为内核插件，记录显示时间的文件永远不会被破坏。
- 它只在你关闭/启动或暂停/恢复游戏时写入文件，这样它就不会破坏你的记忆卡，不像原来的插件。
- 该插件完全支持Adrenaline和Adrenaline气泡。
- 您可以将选定的应用程序/游戏添加到黑名单（位于ux0:/data/TrackPlug/blacklist.txt）
- 该应用程序以每秒60fps的速度运行，而不是以每秒30fps的速度运行。

# 我该如何安装这个？
只需将BetterTrackPlug.skprx放在config.txt中的*KERNEL下即可
```
*KERNEL
ur0:tai/BetterTrackPlug.skprx
```
安装vpk。
重启。

# 我该如何使用它？
- 向上/向下 导航。
- □提示清除所选记录的播放时间，按○选择选项，如果确实清除了播放时间，则会询问是否要将其列入黑名单。

# 笔记
![Bubbles](https://i.imgur.com/qZwPMXU.png)
我建议你设置你的Adrenaline的游戏气泡时，使其标题ID与相应PSP游戏的标题ID相同，而不是默认的PSPEMUXXX，这样，它们将使用同一个存储游戏时间的文件，如果你从Adrenaline气泡或直接从Adrenaline启动游戏，你将不会在列表中看到两个相同的游戏。

由于目前我无法从Adrenaline中提取图标，如果没有相应的气泡，直接从Adrenaline中启动的游戏将不会有任何图标。我也不认为即使我知道怎么做也会有效率。

如果你看到任何错误请让我知道，这将是非常有用的。
# 信用
- 特别感谢**teakhanirons**, [dots-tb](https://github.com/dots-tb), [cuevavirus](https://github.com/cuevavirus/) 以及帮助我制作这个插件的CBP团队，他们不会因为我的问题而失去理智。没有他们的帮助，我甚至不知道从哪里开始制作。
- [Rinnegatamante](https://github.com/Rinnegatamante)在[LPP-Vita](https://github.com/Rinnegatamante/lpp-vita) 首先提出TrackPlug的想法。
- [Electry](https://github.com/Electry/) 的代码块负责在Adrenaline中获得标题。
- **ecamci** 用于制作资产。
- chinseng85添加了存储游戏图标的功能，因此当您删除它们时，您仍然可以看到它们的图标。
- 本人仅将其汉化为中文版本，并添加了字库，恢复了被废除的游戏ID以及游戏区域。
