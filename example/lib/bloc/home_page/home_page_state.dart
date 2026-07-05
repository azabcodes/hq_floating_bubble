part of 'home_page_bloc.dart';

class HomePageState extends Equatable {
  final bool loading;
  final bool ready;
  final bool hasPermission;
  final List<HQFloatingWindow> windows;
  final Map<String, bool> readys;
  final String? errorMessage;

  const HomePageState({
    this.loading = true,
    this.ready = false,
    this.hasPermission = true,
    this.windows = const [],
    this.readys = const {},
    this.errorMessage,
  });

  HomePageState copyWith({
    bool? loading,
    bool? ready,
    bool? hasPermission,
    List<HQFloatingWindow>? windows,
    Map<String, bool>? readys,
    String? errorMessage,
  }) {
    return HomePageState(
      loading: loading ?? this.loading,
      ready: ready ?? this.ready,
      hasPermission: hasPermission ?? this.hasPermission,
      windows: windows ?? this.windows,
      readys: readys ?? this.readys,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        ready,
        hasPermission,
        windows,
        readys,
        errorMessage,
      ];
}
