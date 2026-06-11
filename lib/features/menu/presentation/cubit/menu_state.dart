part of 'menu_cubit.dart';

abstract class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object?> get props => [];
}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<CategoryModel> categories;
  final List<MenuItemModel> menus;
  final int categoryCursor;
  final int menuCursor;
  final bool hasReachedMaxCategories;
  final bool hasReachedMaxMenus;
  final String? currentSearch;
  final String? currentCategoryId;
  final bool isFetchingMoreCategories;
  final bool isFetchingMoreMenus;

  const MenuLoaded({
    required this.categories,
    required this.menus,
    this.categoryCursor = 0,
    this.menuCursor = 0,
    this.hasReachedMaxCategories = false,
    this.hasReachedMaxMenus = false,
    this.currentSearch,
    this.currentCategoryId,
    this.isFetchingMoreCategories = false,
    this.isFetchingMoreMenus = false,
  });

  MenuLoaded copyWith({
    List<CategoryModel>? categories,
    List<MenuItemModel>? menus,
    int? categoryCursor,
    int? menuCursor,
    bool? hasReachedMaxCategories,
    bool? hasReachedMaxMenus,
    String? currentSearch,
    String? currentCategoryId,
    bool? isFetchingMoreCategories,
    bool? isFetchingMoreMenus,
  }) {
    return MenuLoaded(
      categories: categories ?? this.categories,
      menus: menus ?? this.menus,
      categoryCursor: categoryCursor ?? this.categoryCursor,
      menuCursor: menuCursor ?? this.menuCursor,
      hasReachedMaxCategories: hasReachedMaxCategories ?? this.hasReachedMaxCategories,
      hasReachedMaxMenus: hasReachedMaxMenus ?? this.hasReachedMaxMenus,
      currentSearch: currentSearch ?? this.currentSearch,
      currentCategoryId: currentCategoryId ?? this.currentCategoryId,
      isFetchingMoreCategories: isFetchingMoreCategories ?? this.isFetchingMoreCategories,
      isFetchingMoreMenus: isFetchingMoreMenus ?? this.isFetchingMoreMenus,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        menus,
        categoryCursor,
        menuCursor,
        hasReachedMaxCategories,
        hasReachedMaxMenus,
        currentSearch,
        currentCategoryId,
        isFetchingMoreCategories,
        isFetchingMoreMenus,
      ];
}

class MenuError extends MenuState {
  final String message;

  const MenuError({required this.message});

  @override
  List<Object?> get props => [message];
}
