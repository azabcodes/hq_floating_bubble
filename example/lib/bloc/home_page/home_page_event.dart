part of 'home_page_bloc.dart';

abstract class HomePageEvent extends Equatable {
  const HomePageEvent();

  @override
  List<Object?> get props => [];
}

class InitializeServiceAndWindows extends HomePageEvent {
  final List<HQFloatingWindowConfig> configs;

  const InitializeServiceAndWindows(this.configs);

  @override
  List<Object?> get props => [configs];
}

class RefreshServiceStatus extends HomePageEvent {}

class OpenWindowRequested extends HomePageEvent {
  final HQFloatingWindow window;

  const OpenWindowRequested(this.window);

  @override
  List<Object?> get props => [window];
}

class CloseWindowRequested extends HomePageEvent {
  final HQFloatingWindow window;

  const CloseWindowRequested(this.window);

  @override
  List<Object?> get props => [window];
}
