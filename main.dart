import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart'; // Import this package for date formatting

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExpenseProvider()..loadExpenses(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Expense Tracker',
        theme: ThemeData(
          primaryColor: Color(0xFF1E88E5), // Blue color for primary
          hintColor: Color(0xFF43A047), // Green accent color
          buttonTheme: ButtonThemeData(buttonColor: Color(0xFF1E88E5)),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF1E88E5),
          ),
          cardColor: Color(0xFFF3F4F6),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black54),
          ),
        ),
        home: ExpenseTrackerApp(),
      ),
    );
  }
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
    };
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
    );
  }
}

class ExpenseProvider extends ChangeNotifier {
  final ExpenseStorage _expenseStorage = ExpenseStorage();
  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  Future<void> loadExpenses() async {
    _expenses = await _expenseStorage.loadExpenses();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    await _expenseStorage.saveExpenses(_expenses);
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      await _expenseStorage.saveExpenses(_expenses);
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _expenseStorage.saveExpenses(_expenses);
    notifyListeners();
  }

  double getTotalExpenses() {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  List<Expense> getMonthlyExpenses(int month) {
    return _expenses.where((expense) => expense.date.month == month).toList();
  }
}

class ExpenseStorage {
  static const String _expensesKey = 'expenses';

  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getString(_expensesKey);
    if (expensesJson != null) {
      final List<dynamic> expensesData = json.decode(expensesJson);
      return expensesData.map((e) => Expense.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = json.encode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString(_expensesKey, expensesJson);
  }

  Future<void> clearExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_expensesKey);
  }
}

class ExpenseTrackerApp extends StatefulWidget {
  @override
  _ExpenseTrackerAppState createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  double _amount = 0.0;
  DateTime _date = DateTime.now();
  String _category = '';
  Expense? _currentExpense;

  int _selectedMonth = DateTime.now().month;
  bool _showTotalExpenses = false;

  final List<String> _categories = [
    'Food', 'Transport', 'Entertainment', 'Bills', 'Shopping',
    'Health', 'Education', 'Travel', 'Miscellaneous', 'Electronics'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Tracker'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Color(0xFF1E88E5),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Total Expenses', style: TextStyle(color: Colors.white, fontSize: 18)),
                          SizedBox(height: 8),
                          Consumer<ExpenseProvider>(
                            builder: (context, expenseProvider, child) {
                              return Text(
                                '\$${expenseProvider.getTotalExpenses().toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.white, fontSize: 22),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Color(0xFF43A047),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Monthly Expenses', style: TextStyle(color: Colors.white, fontSize: 18)),
                          SizedBox(height: 8),
                          Column(
                            children: [
                              DropdownButton<int>(
                                value: _selectedMonth,
                                items: List.generate(12, (index) {
                                  int month = index + 1;
                                  return DropdownMenuItem(
                                    value: month,
                                    child: Text(_getMonthName(month), style: TextStyle(color: Colors.black)),
                                  );
                                }),
                                onChanged: (month) {
                                  setState(() {
                                    _selectedMonth = month!;
                                  });
                                },
                              ),
                              SizedBox(height: 8),
                              Consumer<ExpenseProvider>(
                                builder: (context, expenseProvider, child) {
                                  final monthlyExpenses = expenseProvider.getMonthlyExpenses(_selectedMonth);
                                  double totalMonthlyExpenses = monthlyExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
                                  return Text(
                                    '\$${totalMonthlyExpenses.toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.white, fontSize: 22),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),

            SwitchListTile(
              title: Text('Show Total Expenses'),
              value: _showTotalExpenses,
              onChanged: (value) {
                setState(() {
                  _showTotalExpenses = value;
                });
              },
            ),

            Expanded(
              child: Consumer<ExpenseProvider>(
                builder: (context, expenseProvider, child) {
                  List<Expense> expensesToShow = _showTotalExpenses
                      ? expenseProvider.expenses
                      : expenseProvider.getMonthlyExpenses(_selectedMonth);

                  if (expensesToShow.isEmpty) {
                    return Center(
                      child: Text(
                        _showTotalExpenses
                            ? 'No expenses available.'
                            : 'No expenses available for this month.',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: expensesToShow.length,
                      itemBuilder: (context, index) {
                        final expense = expensesToShow[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            title: Text(expense.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('\$${expense.amount.toStringAsFixed(2)}', style: TextStyle(color: Colors.green)),
                                Text('Category: ${expense.category}', style: TextStyle(color: Colors.black)),
                                Text('Date: ${DateFormat('yyyy-MM-dd').format(expense.date)}', style: TextStyle(color: Colors.black)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteDialog(context, expense.id);
                              },
                            ),
                            onTap: () {
                              _openExpenseForm(context, expense);
                            },
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openExpenseForm(context, null),
        child: Icon(Icons.add),
      ),
    );
  }

  void _openExpenseForm(BuildContext context, Expense? expense) {
    if (expense != null) {
      _currentExpense = expense.copyWith();
      _title = expense.title;
      _amount = expense.amount;
      _date = expense.date;
      _category = expense.category;
    } else {
      _currentExpense = null;
      _title = '';
      _amount = 0;
      _date = DateTime.now();
      _category = _categories[0];
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    initialValue: _title,
                    decoration: InputDecoration(labelText: 'Expense Title'),
                    onChanged: (value) => _title = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    initialValue: _amount.toString(),
                    decoration: InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      _amount = double.tryParse(value) ?? 0;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    initialValue: _category,
                    decoration: InputDecoration(labelText: 'Category'),
                    onChanged: (value) => _category = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a category.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        final expense = Expense(
                          id: _currentExpense?.id ?? Random().nextInt(1000).toString(),
                          title: _title,
                          amount: _amount,
                          date: _date,
                          category: _category,
                        );

                        if (_currentExpense == null) {
                          context.read<ExpenseProvider>().addExpense(expense);
                        } else {
                          context.read<ExpenseProvider>().updateExpense(expense);
                        }
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(_currentExpense == null ? 'Add Expense' : 'Update Expense'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String expenseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Expense'),
          content: Text('Are you sure you want to delete this expense?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<ExpenseProvider>().deleteExpense(expenseId);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }
}
