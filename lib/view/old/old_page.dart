import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flowermusic/base/app_config.dart';
import 'package:flutter_flowermusic/base/base.dart';
import 'package:flutter_flowermusic/data/song.dart';
import 'package:flutter_flowermusic/main/dialog/dialog.dart';
import 'package:flutter_flowermusic/main/refresh/smart_refresher.dart';
import 'package:flutter_flowermusic/main/tap/opacity_tap_widget.dart';
import 'package:flutter_flowermusic/utils/common_util.dart';
import 'package:flutter_flowermusic/view/old/olddetail_page.dart';
import 'package:flutter_flowermusic/viewmodel/old/old_provide.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class OldPage extends StatefulWidget {
  OldPage();

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _OldContentPage();
  }
}

class _OldContentPage extends State<OldPage> {
  OldProvide _provide = OldProvide();

  final _subscriptions = CompositeSubscription();

  RefreshController _refreshController;

  final _loading = LoadingDialog();

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _refreshController = new RefreshController();

    _loadData();
    _provide.subjectMore.listen((hasMore) {
      if (hasMore) {
        _refreshController.sendBack(false, RefreshStatus.init);
      } else {
        if (_provide.dataArr.length > 0) {
          _refreshController.sendBack(false, RefreshStatus.noMore);
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    print("老歌释放");
    _subscriptions.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provide,
      child: new Scaffold(
        backgroundColor: Color(0xFFF5F5F8),
        appBar: new AppBar(
          title: new Text('经典老歌'),
          centerTitle: true,
          actions: <Widget>[],
        ),
        body: _initView(),
      ),
    );
  }

  Widget _initView() {
    return Selector<OldProvide, int>(
      selector: (_, provide) => provide.dataArr.length,
      builder: (_, value, child) {
        print('_initView');
        return _provide.dataArr.length > 0
            ? _buildListView()
            : AppConfig.initLoading(false);
      },
    );
  }

  _loadData([bool isRefresh = true]) {
    var s = _provide
        .getSongs(isRefresh)
        .doOnListen(() {})
        .doOnCancel(() {})
        .listen((data) {
      if (isRefresh) {
        _refreshController.sendBack(true, RefreshStatus.idle);
      }
    }, onError: (e) {});
    _subscriptions.add(s);
  }

  _onHeaderRefresh() {
    _loadData();
  }

  _onFooterRefresh() {
    if (_provide.hasMore) {
      _loadData(false);
    }
  }

  _onOffsetCallback(bool up, double offset) {}

  Widget _buildListView() {
    return new SmartRefresher(
      child: new ListView.builder(
          itemCount: _provide.dataArr.length,
          itemBuilder: (context, i) {
            if (_provide.dataArr.length > 0) {
              return getRow(_provide.dataArr[i], i);
            }
          }),
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: true,
      onHeaderRefresh: _onHeaderRefresh,
      onFooterRefresh: _onFooterRefresh,
      onOffsetChange: _onOffsetCallback,
    );
  }

  Widget getRow(Song song, int index) {
    return new Container(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
        margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
        color: Colors.white,
        child: new Column(
          children: <Widget>[
            new GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext c) =>
                            OldDetailPage(song: song)));
              },
              child: new Container(
                child: new Row(
                  children: <Widget>[
                    new Expanded(
                        child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        new Text(song.title,
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.left),
                        new Container(
                            height: 80,
                            child: new Html(
                              data: song.desc,
                              defaultTextStyle: TextStyle(
                                  color: Colors.grey, fontSize: 12, height: 1),
                            ))
                      ],
                    )),
                    new CachedNetworkImage(
                      width: 120,
                      height: 120,
                      key: Key(song.imgUrl_s),
                      imageUrl: song.imgUrl_s,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          AppConfig.getPlaceHoder(120.0, 120.0),
                      errorWidget: (context, url, error) =>
                          AppConfig.getPlaceHoder(120.0, 120.0),
                    ),
                  ],
                ),
              ),
            ),
            new Container(
              padding: EdgeInsets.fromLTRB(0, 15, 0, 8),
              child: Row(
                children: <Widget>[
                  new OpacityTapWidget(
                    onTap: () {
                      _provide.setSongs(index);
                    },
                    child: new Icon(
                      Icons.play_circle_outline,
                      color: Colors.black87,
                      size: 28,
                    ),
                  ),
                  new Expanded(
                      child: new Text(
                          song.duration != ''
                              ? ' 时长：' + CommonUtil.dealDuration(song.duration)
                              : '',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.left)),
                  new OpacityTapWidget(
                    onTap: () {
                      try {
                        AppConfig.platform
                            .invokeMethod('share', song.toJson());
                      } catch (e) {}
                    },
                    child: new Icon(
                      Icons.share,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                  new Container(
                    width: 15,
                  ),
                  new InkWell(
                      onTap: () {
                        _clicFav(song);
                      },
                      child: Selector<OldProvide, bool>(
                        selector: (_, provide) => _provide.dataArr[index].isFav,
                        builder: (_, value, child) {
                          return new Icon(
                            value ? Icons.favorite : Icons.favorite_border,
                            size: 22,
                            color: value ? Colors.red : Colors.black87,
                          );
                        },
                      ))
                ],
              ),
            )
          ],
        ));
  }

  _clicFav(Song song) {
    if (AppConfig.userTools.getUserData() == null) {
      Fluttertoast.showToast(msg: "请先登录", gravity: ToastGravity.CENTER);
      return;
    }
    if (song.isFav) {
      showAlert(context, title: '确定要取消收藏？', onlyPositive: false).then((value) {
        if (value) {
          this._uncollectionSong(song.id);
        }
      });
    } else {
      this._collectionSong(song.id);
    }
  }

  _collectionSong(String songId) {
    var s = _provide
        .collectionSong(songId)
        .doOnListen(() {
          _loading.show(context);
        })
        .doOnCancel(() {})
        .listen((data) {
          _loading.hide(context);
        }, onError: (e) {
          _loading.hide(context);
        });
    _subscriptions.add(s);
  }

  _uncollectionSong(String songId) {
    var s = _provide
        .uncollectionSong(songId)
        .doOnListen(() {
          _loading.show(context);
        })
        .doOnCancel(() {})
        .listen((data) {
          _loading.hide(context);
        }, onError: (e) {
          _loading.hide(context);
        });
    _subscriptions.add(s);
  }
}
