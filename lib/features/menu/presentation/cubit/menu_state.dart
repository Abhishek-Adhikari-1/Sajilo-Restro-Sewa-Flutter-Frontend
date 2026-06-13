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
  final String? categorySearch;
  final String? currentCategoryId;
  final bool isFetchingMoreCategories;
  final bool isFetchingMoreMenus;
  final int total;
  final int menuOffset;
  final int limit;
  final int categoryTotal;
  final int categoryOffset;
  final int categoryLimit;
  final bool? currentIsAvailable;
  final Map<String, bool> editedMenus;
  final Map<String, bool> editedCategories;
  final bool? currentCategoryIsAvailable;
  final bool isSaving;
  final String? errorMessage;

  const MenuLoaded({
    required this.categories,
    required this.menus,
    this.categoryCursor = 0,
    this.menuCursor = 0,
    this.hasReachedMaxCategories = false,
    this.hasReachedMaxMenus = false,
    this.currentSearch,
    this.categorySearch,
    this.currentCategoryId,
    this.isFetchingMoreCategories = false,
    this.isFetchingMoreMenus = false,
    this.total = 0,
    this.menuOffset = 0,
    this.limit = 25,
    this.categoryTotal = 0,
    this.categoryOffset = 0,
    this.categoryLimit = 25,
    this.currentIsAvailable,
    this.editedMenus = const {},
    this.editedCategories = const {},
    this.currentCategoryIsAvailable,
    this.isSaving = false,
    this.errorMessage,
  });

  MenuLoaded copyWith({
    List<CategoryModel>? categories,
    List<MenuItemModel>? menus,
    int? categoryCursor,
    int? menuCursor,
    bool? hasReachedMaxCategories,
    bool? hasReachedMaxMenus,
    String? currentSearch,
    String? categorySearch,
    String? currentCategoryId,
    bool? isFetchingMoreCategories,
    bool? isFetchingMoreMenus,
    int? total,
    int? menuOffset,
    int? limit,
    int? categoryTotal,
    int? categoryOffset,
    int? categoryLimit,
    bool? currentIsAvailable,
    Map<String, bool>? editedMenus,
    Map<String, bool>? editedCategories,
    bool? currentCategoryIsAvailable,
    bool? isSaving,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return MenuLoaded(
      categories: categories ?? this.categories,
      menus: menus ?? this.menus,
      categoryCursor: categoryCursor ?? this.categoryCursor,
      menuCursor: menuCursor ?? this.menuCursor,
      hasReachedMaxCategories: hasReachedMaxCategories ?? this.hasReachedMaxCategories,
      hasReachedMaxMenus: hasReachedMaxMenus ?? this.hasReachedMaxMenus,
      currentSearch: currentSearch ?? this.currentSearch,
      categorySearch: categorySearch ?? this.categorySearch,
      currentCategoryId: currentCategoryId ?? this.currentCategoryId,
      isFetchingMoreCategories: isFetchingMoreCategories ?? this.isFetchingMoreCategories,
      isFetchingMoreMenus: isFetchingMoreMenus ?? this.isFetchingMoreMenus,
      total: total ?? this.total,
      menuOffset: menuOffset ?? this.menuOffset,
      limit: limit ?? this.limit,
      categoryTotal: categoryTotal ?? this.categoryTotal,
      categoryOffset: categoryOffset ?? this.categoryOffset,
      categoryLimit: categoryLimit ?? this.categoryLimit,
      currentIsAvailable: currentIsAvailable ?? this.currentIsAvailable,
      editedMenus: editedMenus ?? this.editedMenus,
      editedCategories: editedCategories ?? this.editedCategories,
      currentCategoryIsAvailable: currentCategoryIsAvailable ?? this.currentCategoryIsAvailable,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
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
        categorySearch,
        currentCategoryId,
        isFetchingMoreCategories,
        isFetchingMoreMenus,
        total,
        menuOffset,
        limit,
        categoryTotal,
        categoryOffset,
        categoryLimit,
        currentIsAvailable,
        editedMenus,
        editedCategories,
        currentCategoryIsAvailable,
        isSaving,
        errorMessage,
      ];
}

class MenuError extends MenuState {
  final String message;

  const MenuError({required this.message});

  @override
  List<Object?> get props => [message];
}
