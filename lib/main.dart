import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CaminhadasApp());
}

class Caminhada {
  final String id;
  final String titulo;
  final double distancia;
  final int calorias;
  final int tempo;
  final double latitudeInicial;
  final double longitudeInicial;
  final double latitudeDestino;
  final double longitudeDestino;
  final List<LatLng> rota;
  String? foto;

  Caminhada({
    required this.id,
    required this.titulo,
    required this.distancia,
    required this.calorias,
    required this.tempo,
    required this.latitudeInicial,
    required this.longitudeInicial,
    required this.latitudeDestino,
    required this.longitudeDestino,
    required this.rota,
    this.foto,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'distancia': distancia,
      'calorias': calorias,
      'tempo': tempo,
      'latitudeInicial': latitudeInicial,
      'longitudeInicial': longitudeInicial,
      'latitudeDestino': latitudeDestino,
      'longitudeDestino': longitudeDestino,
      'rota': rota
          .map(
            (ponto) => {
              'latitude': ponto.latitude,
              'longitude': ponto.longitude,
            },
          )
          .toList(),
      'foto': foto,
    };
  }

  factory Caminhada.fromJson(Map<String, dynamic> json) {
    final pontos = (json['rota'] as List<dynamic>? ?? []);

    return Caminhada(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: json['titulo'] ?? 'Caminhada',
      distancia: (json['distancia'] ?? 0).toDouble(),
      calorias: (json['calorias'] ?? 0).toInt(),
      tempo: (json['tempo'] ?? 0).toInt(),
      latitudeInicial: (json['latitudeInicial'] ?? -22.713).toDouble(),
      longitudeInicial: (json['longitudeInicial'] ?? -46.818).toDouble(),
      latitudeDestino: (json['latitudeDestino'] ?? -22.713).toDouble(),
      longitudeDestino: (json['longitudeDestino'] ?? -46.818).toDouble(),
      rota: pontos.map((ponto) {
        return LatLng(
          (ponto['latitude'] ?? 0).toDouble(),
          (ponto['longitude'] ?? 0).toDouble(),
        );
      }).toList(),
      foto: json['foto'],
    );
  }
}

class CaminhadasApp extends StatefulWidget {
  const CaminhadasApp({super.key});

  @override
  State<CaminhadasApp> createState() => _CaminhadasAppState();
}

class _CaminhadasAppState extends State<CaminhadasApp> {
  ThemeMode tema = ThemeMode.light;
  List<Caminhada> caminhadas = [];

  @override
  void initState() {
    super.initState();
    carregarCaminhadas();
  }

  Future<void> carregarCaminhadas() async {
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getString('caminhadas');

    if (dados != null) {
      final lista = jsonDecode(dados) as List<dynamic>;

      setState(() {
        caminhadas = lista
            .map(
              (item) => Caminhada.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      });
    }
  }

  Future<void> salvarLista() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = jsonEncode(
      caminhadas.map((caminhada) => caminhada.toJson()).toList(),
    );

    await prefs.setString('caminhadas', dados);
  }

  Future<void> adicionarCaminhada(Caminhada caminhada) async {
    setState(() {
      caminhadas.add(caminhada);
    });

    await salvarLista();
  }

  Future<void> atualizarCaminhada(Caminhada caminhada) async {
    final indice = caminhadas.indexWhere(
      (item) => item.id == caminhada.id,
    );

    if (indice == -1) {
      return;
    }

    setState(() {
      caminhadas[indice] = caminhada;
    });

    await salvarLista();
  }

  void alternarTema() {
    setState(() {
      tema = tema == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Caminhadas',
      themeMode: tema,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade700,
      body: Center(
        child: FadeTransition(
          opacity: animation,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_walk,
                color: Colors.white,
                size: 100,
              ),
              SizedBox(height: 20),
              Text(
                'Caminhadas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Registre seus caminhos',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState =
        context.findAncestorStateOfType<_CaminhadasAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas caminhadas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: 60,
                      color: Colors.green,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Caminhadas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Início'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Alterar tema'),
                onTap: () {
                  Navigator.pop(context);
                  appState?.alternarTema();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: appState == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : appState.caminhadas.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma caminhada registrada.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appState.caminhadas.length,
                  itemBuilder: (context, index) {
                    final caminhada = appState.caminhadas[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(
                            Icons.directions_walk,
                            color: Colors.green,
                          ),
                        ),
                        title: Text(
                          caminhada.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${caminhada.distancia.toStringAsFixed(2)} km • '
                          '${caminhada.tempo} min • '
                          '${caminhada.calorias} kcal',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalhesPage(
                                caminhada: caminhada,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NovaCaminhadaPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NovaCaminhadaPage extends StatefulWidget {
  const NovaCaminhadaPage({super.key});

  @override
  State<NovaCaminhadaPage> createState() => _NovaCaminhadaPageState();
}

class _NovaCaminhadaPageState extends State<NovaCaminhadaPage> {
  final LatLng pontoInicial = const LatLng(
    -22.7130000,
    -46.8180000,
  );

  final Distance calculadoraDistancia = const Distance();

  LatLng? destino;
  List<LatLng> rota = [];
  double distanciaKm = 0;
  int calorias = 0;
  int tempoMinutos = 0;
  bool carregandoRota = false;

  void selecionarDestino(LatLng novoDestino) {
    final distanciaMetros = calculadoraDistancia.as(
      LengthUnit.Meter,
      pontoInicial,
      novoDestino,
    );

    final distancia = distanciaMetros / 1000;

    setState(() {
      destino = novoDestino;
      distanciaKm = distancia;
      calorias = (distancia * 60).round();
      tempoMinutos = (distancia / 5 * 60).round();
      rota = [
        pontoInicial,
        novoDestino,
      ];
    });

    buscarRota(novoDestino);
  }

  Future<void> buscarRota(LatLng novoDestino) async {
    setState(() {
      carregandoRota = true;
    });

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/walking/'
        '${pontoInicial.longitude},${pontoInicial.latitude};'
        '${novoDestino.longitude},${novoDestino.latitude}'
        '?overview=full&geometries=geojson',
      );

      final resposta = await http.get(url).timeout(
        const Duration(seconds: 8),
      );

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);

        final rotaJson =
            dados['routes'][0]['geometry']['coordinates'] as List;

        final novaRota = rotaJson.map<LatLng>((ponto) {
          return LatLng(
            (ponto[1] as num).toDouble(),
            (ponto[0] as num).toDouble(),
          );
        }).toList();

        final distanciaRota =
            (dados['routes'][0]['distance'] as num).toDouble() / 1000;

        final novoTempo =
            (distanciaRota / 5 * 60).round();

        final novasCalorias =
            (distanciaRota * 60).round();

        if (mounted) {
          setState(() {
            rota = novaRota;
            distanciaKm = distanciaRota;
            tempoMinutos = novoTempo;
            calorias = novasCalorias;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          rota = [
            pontoInicial,
            novoDestino,
          ];
        });
      }
    }

    if (mounted) {
      setState(() {
        carregandoRota = false;
      });
    }
  }

  Future<void> salvarCaminhada() async {
    if (destino == null) {
      return;
    }

    final controller = TextEditingController();

    final titulo = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Salvar caminhada'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome da caminhada',
              hintText: 'Ex.: Caminhada no parque',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nome = controller.text.trim();

                if (nome.isNotEmpty) {
                  Navigator.of(dialogContext).pop(nome);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (titulo == null || titulo.isEmpty || !mounted) {
      return;
    }

    final appState =
        context.findAncestorStateOfType<_CaminhadasAppState>();

    if (appState == null) {
      return;
    }

    final caminhada = Caminhada(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: titulo,
      distancia: distanciaKm,
      calorias: calorias,
      tempo: tempoMinutos,
      latitudeInicial: pontoInicial.latitude,
      longitudeInicial: pontoInicial.longitude,
      latitudeDestino: destino!.latitude,
      longitudeDestino: destino!.longitude,
      rota: rota,
    );

    await appState.adicionarCaminhada(caminhada);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nova caminhada',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              destino == null
                  ? 'Toque no mapa para escolher o destino'
                  : 'Destino selecionado',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: pontoInicial,
                initialZoom: 15,
                onTap: (tapPosition, latLng) {
                  selecionarDestino(latLng);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.caminhadas',
                ),
                if (rota.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: rota,
                        strokeWidth: 5,
                        color: Colors.green,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pontoInicial,
                      width: 45,
                      height: 45,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 45,
                      ),
                    ),
                    if (destino != null)
                      Marker(
                        point: destino!,
                        width: 45,
                        height: 45,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 45,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (destino != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (carregandoRota)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text('Calculando rota...'),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Informacao(
                        icone: Icons.straighten,
                        titulo: 'Distância',
                        valor:
                            '${distanciaKm.toStringAsFixed(2)} km',
                      ),
                      _Informacao(
                        icone: Icons.local_fire_department,
                        titulo: 'Calorias',
                        valor: '$calorias kcal',
                      ),
                      _Informacao(
                        icone: Icons.timer,
                        titulo: 'Tempo',
                        valor: '$tempoMinutos min',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: salvarCaminhada,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar caminhada'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class DetalhesPage extends StatefulWidget {
  final Caminhada caminhada;

  const DetalhesPage({
    super.key,
    required this.caminhada,
  });

  @override
  State<DetalhesPage> createState() => _DetalhesPageState();
}

class _DetalhesPageState extends State<DetalhesPage> {
  late Caminhada caminhada;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    caminhada = widget.caminhada;
  }

  Future<void> tirarFoto() async {
    final foto = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (foto == null || !mounted) {
      return;
    }

    final appState =
        context.findAncestorStateOfType<_CaminhadasAppState>();

    if (appState == null) {
      return;
    }

    final atualizada = Caminhada(
      id: caminhada.id,
      titulo: caminhada.titulo,
      distancia: caminhada.distancia,
      calorias: caminhada.calorias,
      tempo: caminhada.tempo,
      latitudeInicial: caminhada.latitudeInicial,
      longitudeInicial: caminhada.longitudeInicial,
      latitudeDestino: caminhada.latitudeDestino,
      longitudeDestino: caminhada.longitudeDestino,
      rota: caminhada.rota,
      foto: foto.path,
    );

    await appState.atualizarCaminhada(atualizada);

    if (!mounted) {
      return;
    }

    setState(() {
      caminhada = atualizada;
    });
  }

  @override
  Widget build(BuildContext context) {
    final origem = LatLng(
      caminhada.latitudeInicial,
      caminhada.longitudeInicial,
    );

    final destino = LatLng(
      caminhada.latitudeDestino,
      caminhada.longitudeDestino,
    );

    final pontos = caminhada.rota.length >= 2
        ? caminhada.rota
        : [origem, destino];

    return Scaffold(
      appBar: AppBar(
        title: Text(caminhada.titulo),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: destino,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.caminhadas',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: pontos,
                      strokeWidth: 5,
                      color: Colors.green,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: origem,
                      width: 45,
                      height: 45,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 45,
                      ),
                    ),
                    Marker(
                      point: destino,
                      width: 45,
                      height: 45,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caminhada.titulo,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Informacao(
                      icone: Icons.straighten,
                      titulo: 'Distância',
                      valor:
                          '${caminhada.distancia.toStringAsFixed(2)} km',
                    ),
                    _Informacao(
                      icone: Icons.local_fire_department,
                      titulo: 'Calorias',
                      valor: '${caminhada.calorias} kcal',
                    ),
                    _Informacao(
                      icone: Icons.timer,
                      titulo: 'Tempo',
                      valor: '${caminhada.tempo} min',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (caminhada.foto != null &&
                    File(caminhada.foto!).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(caminhada.foto!),
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.green.withValues(alpha: 0.1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          size: 70,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhuma foto adicionada',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: tirarFoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Tirar foto'),
                        ),
                      ],
                    ),
                  ),
                if (caminhada.foto != null &&
                    File(caminhada.foto!).existsSync())
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: tirarFoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tirar outra foto'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Informacao extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;

  const _Informacao({
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icone,
          color: Colors.green,
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          titulo,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}