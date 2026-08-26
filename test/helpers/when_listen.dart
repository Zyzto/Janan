import 'package:mockito/mockito.dart';

/// Stubs [cubit.state] / [cubit.stream] the way `bloc_test`'s `whenListen` did.
void whenListen<S>(
  dynamic cubit,
  Stream<S> stream, {
  required S initialState,
}) {
  when(cubit.state).thenReturn(initialState);
  when(cubit.stream).thenAnswer((_) => stream);
  when(cubit.isClosed).thenReturn(false);
  stream.listen((state) {
    when(cubit.state).thenReturn(state);
  });
}
