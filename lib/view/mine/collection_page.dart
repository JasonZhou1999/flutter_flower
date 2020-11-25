import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flowermusic/base/app_config.dart';
import 'package:flutter_flowermusic/base/base.dart';
import 'package:flutter_flowermusic/data/song.dart';
import 'package:flutter_flowermusic/main/dialog/dialog.dart';
import 'package:flutter_flowermusic/main/refresh/smart_refresher.dart';
import 'package:flutter_flowermusic/utils/common_util.dart';
import 'package:flutter_flowermusic/viewmodel/mine/collection_provide.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class CollectionPage extends StatefulWidget {

  CollectionPage();

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _CollectionContentState();
  }
}

class _CollectionContentState extends State<CollectionPage> {

  CollectionProvide _provider = CollectionProvide();
  RefreshController _refreshController;
  final _subscriptions = CompositeSubscription();
  final _loading = LoadingDialog();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _refreshController = new RefreshController();
    _loadData();
  }
  _loadData() {
    var s = _provider.favList().doOnListen(() {
    }).doOnCancel(() {
    }).listen((data) {
      _refreshController.sendBack(true, RefreshStatus.idle);
    }, onError: (e) {
    });
    _subscriptions.add(s);
  }
  _uncollectionSong(String songId) {
    var s = _provider.uncollectionSong(songId).doOnListen(() {
      _loading.show(context);
    }).doOnCancel(() {
    }).listen((data) {
      _loading.hide(context);
    }, onError: (e) {
      _loading.hide(context);
    });
    _subscriptions.add(s);
  }
  @override
  void dispose() {
    super.dispose();
    _subscriptions.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text('我的收藏'),
          centerTitle: true,
        ),
        body: _initView(),
      ),
    );
  }

  Widget _initView() {
    return Selector<CollectionProvide, int>(
      selector: (_, provide) => provide.dataArr.length,
      builder: (_, value, child) {
        return value > 0 ? _buildListView() : AppConfig
            .initLoading(_provider.showEmpty, '暂无收藏');
      },
    );
  }

  Widget _buildListView() {
    return new SmartRefresher(
      child: new ListView.builder(
          itemCount: _provider.dataArr.length,
          itemBuilder: (context, i) {
            if (_provider.dataArr.length > 0) {
              return new Dismissible(
                  key: new Key(_provider.dataArr[i].id),
                  confirmDismiss: (DismissDirection direction) async {
                    bool res = await showAlert(context, title: '确定要取消收藏该歌曲？', onlyPositive: false);
                    return res;
                  },
                  onDismissed: (direction) {
                    this._uncollectionSong(_provider.dataArr[i].id);
                  },
                  child: getRow(_provider.dataArr[i]));
            }
          }),
      controller:_refreshController,
      enablePullDown: true,
      enablePullUp: false,
      onHeaderRefresh: _onHeaderRefresh,
    );
  }

  Widget getRow(Song song) {
    return new GestureDetector(
      onTap: () {

      },
      child: new Column(
        children: <Widget>[
          new Container(
            height: 70,
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            color: Colors.white,
            child: new Row(children: <Widget>[
              new CachedNetworkImage(
                width: 70,
                height: 70,
                key: Key(song.imgUrl_s),
                imageUrl: song.imgUrl_s,
                fit: BoxFit.cover,
                placeholder: (context, url) => AppConfig.getPlaceHoder(70.0, 70.0),
                errorWidget: (context, url, error) => AppConfig.getPlaceHoder(70.0, 70.0),
              ),
              new Container(
                width: 8,
              ),
              new Expanded(child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Container(height: 4,),
                  new Text(song.title, style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold),textAlign: TextAlign.left),
                  new Container(height: 8,),
                  new Text(song.duration != '' ? ' 时长：' + CommonUtil.dealDuration(song.duration):'', style: TextStyle(color: Colors.grey, fontSize: 12),textAlign: TextAlign.left)
                ],)),
            ],),),
        ],
      ),
    );
  }

  _onHeaderRefresh() {
    _loadData();
  }
}