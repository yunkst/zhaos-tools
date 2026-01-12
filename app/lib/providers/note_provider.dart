import 'package:flutter/foundation.dart';
import 'package:teacher_tools/models/note.dart';
import 'package:teacher_tools/database/note_dao.dart';

/// 笔记状态管理Provider
class NoteProvider with ChangeNotifier {
  final NoteDAO _noteDAO = NoteDAO();

  // 笔记列表
  List<Note> _notes = [];
  List<Note> get notes => _notes;

  // 最近笔记
  List<Note> _recentNotes = [];
  List<Note> get recentNotes => _recentNotes;

  // 加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 错误信息
  String? _error;
  String? get error => _error;

  /// 根据 ID 获取笔记
  Future<Note?> getNoteById(int id) async {
    try {
      return await _noteDAO.getById(id);
    } catch (e) {
      debugPrint('Error getting note by id: $e');
      return null;
    }
  }

  /// 加载班级笔记
  Future<void> loadNotes(int classId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _noteDAO.getByClassId(classId);
    } catch (e) {
      debugPrint('Error loading notes: $e');
      _error = '加载失败: $e';
      _notes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载最近笔记
  Future<void> loadRecentNotes(int classId) async {
    try {
      _recentNotes = await _noteDAO.getRecentNotes(classId, limit: 10);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recent notes: $e');
    }
  }

  /// 加载学生笔记
  Future<List<Note>> loadStudentNotes(int studentId) async {
    try {
      return await _noteDAO.getByStudentId(studentId);
    } catch (e) {
      debugPrint('Error loading student notes: $e');
      return [];
    }
  }

  /// 添加笔记
  Future<bool> addNote(Note note) async {
    try {
      final id = await _noteDAO.insert(note);
      final newNote = note.copyWith(id: id);
      _notes.insert(0, newNote);
      _recentNotes.insert(0, newNote);

      // 限制最近笔记数量
      if (_recentNotes.length > 10) {
        _recentNotes = _recentNotes.sublist(0, 10);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding note: $e');
      return false;
    }
  }

  /// 更新笔记
  Future<bool> updateNote(Note note) async {
    try {
      await _noteDAO.update(note);

      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
      }

      final recentIndex = _recentNotes.indexWhere((n) => n.id == note.id);
      if (recentIndex != -1) {
        _recentNotes[recentIndex] = note;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating note: $e');
      return false;
    }
  }

  /// 删除笔记
  Future<bool> deleteNote(int id) async {
    try {
      await _noteDAO.delete(id);
      _notes.removeWhere((n) => n.id == id);
      _recentNotes.removeWhere((n) => n.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting note: $e');
      return false;
    }
  }

  /// 按标签搜索
  Future<List<Note>> searchByTag(int classId, String tag) async {
    try {
      return await _noteDAO.searchByTag(classId, tag);
    } catch (e) {
      debugPrint('Error searching notes by tag: $e');
      return [];
    }
  }

  /// 搜索笔记
  List<Note> searchNotes(String keyword) {
    return _notes
        .where((n) =>
            (n.title != null && n.title!.contains(keyword)) ||
            n.content.contains(keyword))
        .toList();
  }

  /// 获取笔记数量
  int getNoteCount() {
    return _notes.length;
  }

  /// 获取学生的笔记数量
  Future<int> getStudentNoteCount(int studentId) async {
    try {
      final notes = await _noteDAO.getByStudentId(studentId);
      return notes.length;
    } catch (e) {
      debugPrint('Error getting student note count: $e');
      return 0;
    }
  }
}
