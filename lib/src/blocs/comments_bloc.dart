import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../models/item_model.dart';
import '../resources/repository.dart';

class CommentsBloc {
  final _repository = Repository();
  final _commentsFetcher = PublishSubject<int>();
  final _commentsOutput = BehaviorSubject<Map<int, Future<ItemModel>>>();

  //  Stream getters
  Observable<Map<int, Future<ItemModel>>> get itemWithComments =>
      _commentsOutput.stream;

  //  Sink getters
  Function(int) get fetchItemWithComments => _commentsFetcher.sink.add;

  //  Connecting Fetcher and Output
  CommentsBloc() {
    _commentsFetcher.stream.transform(_commentsTransformer()).pipe(_commentsOutput);
  }

  //  Transformer
  _commentsTransformer(){
    //  Use ScanStreamTransformer Because We Need To Maintain Cache
    return ScanStreamTransformer<int, Map<int, Future<ItemModel>>>(
        //  Executed anytime new data comes into transformer
        (cache, int id, index){
          // Fetch Id
          cache[id] = _repository.fetchItem(id);
          cache[id].then((ItemModel item){
            item.kids.forEach((kidId) => fetchItemWithComments(kidId));
          });
          return cache;
        },
      //  Empty map to serve as cache
      <int, Future<ItemModel>>{},
    );
  }

  dispose() {
    _commentsFetcher.close();
    _commentsOutput.close();
  }
}
