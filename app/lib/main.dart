import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tarefas',
      theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity),
      home: MyHomePage(title: 'Pagina Inicial'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _todoController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List _todoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

//#region INITSTATE
  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }
//#endregion

  void _addTodo() {
    if (_formKey.currentState.validate()) {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = _todoController.text;
      newTodo["ok"] = false;
      _todoController.text = "";
      setState(() {
        _todoList.add(newTodo);
      });
      _saveData();
    }
  }

  void _changeValueTodo(bool value, int index) {
    setState(() {
      _todoList[index]["ok"] = value;
    });
    _saveData();
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
    });
    _saveData();
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lista de Tarefas",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(children: [
        Form(
            key: _formKey,
            child: Container(
                padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
                child: Row(children: [
                  Expanded(
                      child: TextFormField(
                    onFieldSubmitted: (value) {
                      _addTodo();
                    },
                    onChanged: (value) {
                      _formKey.currentState.validate();
                    },
                    controller: _todoController,
                    validator: (value) {
                      if (value.isEmpty)
                        return "o Nome da tarefa não pode ser vazio.";
                      else
                        return "";
                    },
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle:
                            TextStyle(color: Theme.of(context).primaryColor)),
                  )),
                  RaisedButton(
                    color: Theme.of(context).primaryColor,
                    onPressed: _addTodo,
                    child: Text("Add"),
                    textColor: Colors.white,
                  )
                ]))),
        Expanded(
          child: RefreshIndicator(
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _todoList.length,
                itemBuilder: builderIten),
            onRefresh: _refresh,
          ),
        )
      ]),
    );
  }

  Widget builderIten(context, index) {
    return Dismissible(
        key: Key(DateTime.now().millisecond.toString()),
        background: Container(
          color: Colors.red,
          child: Align(
              alignment: Alignment(-0.9, 0.0),
              child: Icon(
                Icons.delete,
                color: Colors.white,
              )),
        ),
        direction: DismissDirection.startToEnd,
        onDismissed: (direction) {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPos = index;
          setState(() {
            _todoList.removeAt(index);
          });
          _saveData();
          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovedPos, _lastRemoved);
                });
                _saveData();
              },
            ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        },
        child: CheckboxListTile(
          title: Text(_todoList[index]["title"]),
          value: _todoList[index]["ok"],
          onChanged: (newValue) {
            _changeValueTodo(newValue, index);
          },
          secondary: CircleAvatar(
            foregroundColor: Colors.white,
            backgroundColor: _todoList[index]["ok"]
                ? Theme.of(context).primaryColor
                : Colors.red,
            child: Icon(_todoList[index]["ok"] ? Icons.check : Icons.error),
          ),
        ));
  }

//#region Metodos
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/taskd.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);

    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
//#endregion
}
