/// Task list sorting fields used by the Tasks UI.
///
/// NOTE: This enum lives in the UI layer because it's presentation logic.
/// Providers and domain models should not depend on this.
enum TaskSortField {
  /// Sort by task.createdAt
  createdAt,

  /// Sort by task.updatedAt
  updatedAt,

  /// Sort by task.dueDate
  dueDate,

  /// Sort by planned schedule start date (TaskProvider schedule meta).
  scheduleStart,

  /// Sort by completedAt (doneAt). If a task is not completed, it will be treated
  /// as far-future when sorting ascending.
  completedAt,
}

extension TaskSortFieldLabel on TaskSortField {
  String get label {
    switch (this) {
      case TaskSortField.createdAt:
        return '작성일';
      case TaskSortField.updatedAt:
        return '수정일';
      case TaskSortField.dueDate:
        return '기한';
      case TaskSortField.scheduleStart:
        return '계획';
      case TaskSortField.completedAt:
        return '완료일';
    }
  }
}
