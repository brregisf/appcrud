import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Modelo do Planeta
class Planeta {
  int? id;
  String nome;
  String? apelido;
  double distancia;
  double tamanho;

  Planeta({this.id, required this.nome, this.apelido, required this.distancia, required this.tamanho});

  Map<String, dynamic> toMap() {
    return {'id': id, 'nome': nome, 'apelido': apelido, 'distancia': distancia, 'tamanho': tamanho};
  }
}

// Banco de Dados
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async => _database ??= await _initDB('planetas.db');

  Future<Database> _initDB(String filePath) async {
    final path = join(await getDatabasesPath(), filePath);
    return openDatabase(path, version: 1, onCreate: (db, _) {
      db.execute('''CREATE TABLE planetas (id INTEGER PRIMARY KEY, nome TEXT, apelido TEXT, distancia REAL, tamanho REAL)''');
    });
  }

  Future<int> insertPlaneta(Planeta planeta) async {
    final db = await database;
    return await db.insert('planetas', planeta.toMap());
  }

  Future<List<Planeta>> readAllPlanetas() async {
    final db = await database;
    final result = await db.query('planetas');
    return result.map((json) => Planeta(
      id: json['id'] as int?,
      nome: json['nome'] as String,
      apelido: json['apelido'] as String?,
      distancia: json['distancia'] as double,
      tamanho: json['tamanho'] as double,
    )).toList();
  }

  Future<int> updatePlaneta(Planeta planeta) async {
    final db = await database;
    return await db.update('planetas', planeta.toMap(), where: 'id = ?', whereArgs: [planeta.id]);
  }

  Future<int> deletePlaneta(int id) async {
    final db = await database;
    return await db.delete('planetas', where: 'id = ?', whereArgs: [id]);
  }
}

// App Principal com Cadastro e Detalhes
void main() => runApp(MaterialApp(home: ListaPlanetas()));

class ListaPlanetas extends StatefulWidget {
  @override
  _ListaPlanetasState createState() => _ListaPlanetasState();
}

class _ListaPlanetasState extends State<ListaPlanetas> {
  final dbHelper = DatabaseHelper.instance;
  List<Planeta> planetas = [];

  @override
  void initState() {
    super.initState();
    carregarPlanetas();
  }

  Future<void> carregarPlanetas() async {
    final data = await dbHelper.readAllPlanetas();
    setState(() => planetas = data);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Planetas')),
    body: ListView.builder(
      itemCount: planetas.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(planetas[index].nome),
        subtitle: Text(planetas[index].apelido ?? 'Sem apelido'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CadastroPlaneta(planeta: planetas[index]))).then((_) => carregarPlanetas()),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                await dbHelper.deletePlaneta(planetas[index].id!);
                carregarPlanetas();
              },
            ),
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CadastroPlaneta())).then((_) => carregarPlanetas()),
      child: Icon(Icons.add),
    ),
  );
}

class CadastroPlaneta extends StatefulWidget {
  final Planeta? planeta;

  CadastroPlaneta({this.planeta});

  @override
  _CadastroPlanetaState createState() => _CadastroPlanetaState();
}

class _CadastroPlanetaState extends State<CadastroPlaneta> {
  final nomeController = TextEditingController();
  final apelidoController = TextEditingController();
  final distanciaController = TextEditingController();
  final tamanhoController = TextEditingController();
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    if (widget.planeta != null) {
      nomeController.text = widget.planeta!.nome;
      apelidoController.text = widget.planeta!.apelido ?? '';
      distanciaController.text = widget.planeta!.distancia.toString();
      tamanhoController.text = widget.planeta!.tamanho.toString();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.planeta == null ? 'Cadastrar Planeta' : 'Editar Planeta')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(controller: nomeController, decoration: InputDecoration(labelText: 'Nome')),
          TextField(controller: apelidoController, decoration: InputDecoration(labelText: 'Apelido (Opcional)')),
          TextField(controller: distanciaController, decoration: InputDecoration(labelText: 'Distância'), keyboardType: TextInputType.number),
          TextField(controller: tamanhoController, decoration: InputDecoration(labelText: 'Tamanho'), keyboardType: TextInputType.number),
          SizedBox(height: 20),
          ElevatedButton(onPressed: () async {
            final planeta = Planeta(
              id: widget.planeta?.id,
              nome: nomeController.text,
              apelido: apelidoController.text.isEmpty ? null : apelidoController.text,
              distancia: double.parse(distanciaController.text),
              tamanho: double.parse(tamanhoController.text),
            );
            if (widget.planeta == null) {
              await dbHelper.insertPlaneta(planeta);
            } else {
              await dbHelper.updatePlaneta(planeta);
            }
            Navigator.pop(context);
          }, child: Text('Salvar')),
        ],
      ),
    ),
  );
}