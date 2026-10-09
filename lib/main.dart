import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
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
          .map((ponto) => {
                'latitude': ponto.latitude,
                'longitude': ponto.longitude,
              })
          .toList(),
      'foto': foto,
    };
  }

  factory Caminhada.fromJson(Map<String, dynamic> json) {
    final pontos = json['rota'] as List<dynamic>? ?? [];

    return Caminhada(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: json['titulo']?.toString() ?? 'Caminhada',
      distancia: (json['distancia'] as num? ?? 0).toDouble(),
      calorias: (json['calorias'] as num? ?? 0).toInt(),
      tempo: (json['tempo'] as num? ?? 0).toInt(),
      latitudeInicial:
          (json['latitudeInicial'] as num? ?? -22.713).toDouble(),
      longitudeInicial:
          (json['longitudeInicial'] as num? ?? -46.818).toDouble(),
      latitudeDestino:
          (json['latitudeDestino'] as num? ?? -22.713).toDouble(),
      longitudeDestino:
          (json['longitudeDestino'] as num? ?? -46.818).toDouble(),
      rota: pontos.map<LatLng>((ponto) {
        final dados = Map<String, dynamic>.from(ponto);
        return LatLng(
          (dados['latitude'] as num? ?? 0).toDouble(),
          (dados['longitude'] as num? ?? 0).toDouble(),
        );
      }).toList(),
      foto: json['foto']?.toString(),
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

    if (dados == null) {
      return;
    }

    try {
      final lista = jsonDecode(dados) as List<dynamic>;

      if (!mounted) {
        return;
      }

      setState(() {
        caminhadas = lista
            .map((item) => Caminhada.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList();
      });
    } catch (_) {
      setState(() {
        caminhadas = [];
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
  late final AnimationController controller;
  late final Animation<double> animation;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    controller.forward();

    timer = Timer(const Duration(milliseconds: 2500), () async {
      if (!mounted) {
        return;
      }

      await controller.reverse();

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
    timer?.cancel();
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
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1,
            ).animate(animation),
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
                leading: const Icon(Icons.animation),
                title: const Text('Splash'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SplashPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Tema claro/escuro'),
                onTap: () {
                  Navigator.pop(context);
                  appState?.alternarTema();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () {
                  SystemNavigator.pop();
                },
              ),
            ],
          ),
        ),
      ),
      body: appState == null
          ? const Center(child: CircularProgressIndicator())
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
                        onTap: () async {
                          await Navigator.push(
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
        onPressed: () async {
          await Navigator.push(
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
      rota = [pontoInicial, novoDestino];
    });

    buscarRota(novoDestino);
  }

  Future<void> buscarRota(LatLng novoDestino) async {
    setState(() {
      carregandoRota = true;
    });

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/foot/'
        '${pontoInicial.longitude},${pontoInicial.latitude};'
        '${novoDestino.longitude},${novoDestino.latitude}'
        '?overview=full&geometries=geojson',
      );

      final resposta = await http.get(url).timeout(
            const Duration(seconds: 15),
          );

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);
        final rotas = dados['routes'] as List<dynamic>;

        if (rotas.isEmpty) {
          throw Exception('Nenhuma rota encontrada.');
        }

        final primeiraRota = rotas.first;
        final coordenadas =
            primeiraRota['geometry']['coordinates'] as List<dynamic>;

        final novaRota = coordenadas.map<LatLng>((ponto) {
          return LatLng(
            (ponto[1] as num).toDouble(),
            (ponto[0] as num).toDouble(),
          );
        }).toList();

        final distanciaRota =
            (primeiraRota['distance'] as num).toDouble() / 1000;

        if (mounted) {
          setState(() {
            rota = novaRota;
            distanciaKm = distanciaRota;
            tempoMinutos = (distanciaRota / 5 * 60).round();
            calorias = (distanciaRota * 60).round();
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          rota = [pontoInicial, novoDestino];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          carregandoRota = false;
        });
      }
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
                        valor: '${distanciaKm.toStringAsFixed(2)} km',
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
  bool tirandoFoto = false;

  @override
  void initState() {
    super.initState();
    caminhada = widget.caminhada;
  }

  Future<void> tirarFoto() async {
    if (tirandoFoto) {
      return;
    }

    setState(() {
      tirandoFoto = true;
    });

    try {
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
        throw Exception('Não foi possível acessar as caminhadas.');
      }

      final diretorio = await getApplicationDocumentsDirectory();
      final pastaFotos = Directory('${diretorio.path}/fotos');

      await pastaFotos.create(recursive: true);

      final arquivoFoto = await File(foto.path).copy(
        '${pastaFotos.path}/foto_${caminhada.id}.jpg',
      );

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
        foto: arquivoFoto.path,
      );

      await appState.atualizarCaminhada(atualizada);

      if (!mounted) {
        return;
      }

      setState(() {
        caminhada = atualizada;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto salva com sucesso!'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao tirar ou salvar a foto: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          tirandoFoto = false;
        });
      }
    }
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

    final temFoto = caminhada.foto != null &&
        File(caminhada.foto!).existsSync();

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
                if (pontos.length >= 2)
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
                if (temFoto)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(caminhada.foto!),
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          height: 220,
                          child: Center(
                            child: Text('Não foi possível carregar a foto.'),
                          ),
                        );
                      },
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
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 70,
                          color: Colors.green,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Nenhuma foto adicionada',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: tirandoFoto ? null : tirarFoto,
                    icon: tirandoFoto
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(
                      tirandoFoto
                          ? 'Abrindo câmera...'
                          : temFoto
                              ? 'Tirar outra foto'
                              : 'Tirar foto',
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