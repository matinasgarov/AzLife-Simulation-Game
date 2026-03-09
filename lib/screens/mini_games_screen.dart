import 'dart:math';
import 'package:flutter/material.dart';

class MiniGameResult {
  final String gameName;
  final String outcome; // win, draw, lose
  final int relationshipDelta;
  final int happinessDelta;
  final String logMessage;

  const MiniGameResult({
    required this.gameName,
    required this.outcome,
    required this.relationshipDelta,
    required this.happinessDelta,
    required this.logMessage,
  });
}

class MiniGamesScreen extends StatelessWidget {
  final String personName;

  const MiniGamesScreen({super.key, required this.personName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("$personName ilə oyun"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _gameTile(context, "chess", "Şahmat", Icons.psychology_outlined, "Real taxtada oynanır."),
          _gameTile(context, "domino", "Domino", Icons.grid_on_rounded, "Real daş oyunu."),
          _gameTile(context, "backgammon", "Nərd", Icons.casino_outlined, "Sadələşdirilmiş mini oyun."),
        ],
      ),
    );
  }

  Widget _gameTile(BuildContext context, String gameId, String gameName, IconData icon, String desc) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(gameName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final result = await Navigator.push<MiniGameResult>(
            context,
            MaterialPageRoute(
              builder: (_) => gameId == "chess"
                  ? RealChessGameScreen(personName: personName)
                  : (gameId == "domino"
                        ? RealDominoGameScreen(personName: personName)
                        : QuickBoardGameScreen(personName: personName, gameName: gameName)),
            ),
          );
          if (context.mounted) {
            Navigator.pop(context, result);
          }
        },
      ),
    );
  }
}

class RealChessGameScreen extends StatefulWidget {
  final String personName;

  const RealChessGameScreen({super.key, required this.personName});

  @override
  State<RealChessGameScreen> createState() => _RealChessGameScreenState();
}

class _ChessMove {
  final int fr;
  final int fc;
  final int tr;
  final int tc;

  const _ChessMove(this.fr, this.fc, this.tr, this.tc);
}

class _RealChessGameScreenState extends State<RealChessGameScreen> {
  final Random _random = Random();
  late List<List<String>> _board;
  int? _selectedR;
  int? _selectedC;
  List<_ChessMove> _selectedMoves = [];
  bool _isGameOver = false;
  bool _fatherThinking = false;
  MiniGameResult? _result;
  String _status = "Sənin növbəndir.";

  static const Map<String, String> _pieceImage = {
    "P": "assets/gameImages/pawn.png",
    "R": "assets/gameImages/rook.png",
    "N": "assets/gameImages/knight.png",
    "B": "assets/gameImages/bishop.png",
    "Q": "assets/gameImages/queen.png",
    "K": "assets/gameImages/king.png",
    "p": "assets/gameImages/pawn1.png",
    "r": "assets/gameImages/rook.png",
    "n": "assets/gameImages/knight1.png",
    "b": "assets/gameImages/bishop1.png",
    "q": "assets/gameImages/queen1.png",
    "k": "assets/gameImages/king1.png",
  };

  @override
  void initState() {
    super.initState();
    _board = _initialBoard();
  }

  List<List<String>> _initialBoard() {
    return [
      ["r", "n", "b", "q", "k", "b", "n", "r"],
      ["p", "p", "p", "p", "p", "p", "p", "p"],
      ["", "", "", "", "", "", "", ""],
      ["", "", "", "", "", "", "", ""],
      ["", "", "", "", "", "", "", ""],
      ["", "", "", "", "", "", "", ""],
      ["P", "P", "P", "P", "P", "P", "P", "P"],
      ["R", "N", "B", "Q", "K", "B", "N", "R"],
    ];
  }

  bool _inBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  bool _isWhite(String piece) => piece.isNotEmpty && piece == piece.toUpperCase();
  bool _isBlack(String piece) => piece.isNotEmpty && piece == piece.toLowerCase();

  List<List<String>> _cloneBoard(List<List<String>> board) {
    return board.map((row) => List<String>.from(row)).toList(growable: false);
  }

  void _applyMoveOnBoard(List<List<String>> board, _ChessMove move) {
    final moving = board[move.fr][move.fc];
    board[move.fr][move.fc] = "";
    board[move.tr][move.tc] = moving;

    if (moving == "P" && move.tr == 0) board[move.tr][move.tc] = "Q";
    if (moving == "p" && move.tr == 7) board[move.tr][move.tc] = "q";
  }

  ({int r, int c})? _findKing(List<List<String>> board, bool whiteKing) {
    final king = whiteKing ? "K" : "k";
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c] == king) return (r: r, c: c);
      }
    }
    return null;
  }

  bool _isSquareAttacked(List<List<String>> board, int targetR, int targetC, {required bool byWhite}) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece.isEmpty) continue;
        if (byWhite && !_isWhite(piece)) continue;
        if (!byWhite && !_isBlack(piece)) continue;

        final pseudo = _pseudoMovesForPiece(board, r, c, white: byWhite, forAttack: true);
        if (pseudo.any((m) => m.tr == targetR && m.tc == targetC)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isKingInCheck(List<List<String>> board, bool whiteKing) {
    final kingPos = _findKing(board, whiteKing);
    if (kingPos == null) return true;
    return _isSquareAttacked(board, kingPos.r, kingPos.c, byWhite: !whiteKing);
  }

  List<_ChessMove> _pseudoMovesForPiece(
    List<List<String>> board,
    int r,
    int c, {
    required bool white,
    bool forAttack = false,
  }) {
    final piece = board[r][c];
    if (piece.isEmpty) return [];
    final p = piece.toUpperCase();
    final moves = <_ChessMove>[];

    bool canCapture(int tr, int tc) {
      if (!_inBounds(tr, tc)) return false;
      final target = board[tr][tc];
      if (target.isEmpty) return false;
      if (target.toUpperCase() == "K") return false;
      return white ? _isBlack(target) : _isWhite(target);
    }

    bool canMoveTo(int tr, int tc) {
      if (!_inBounds(tr, tc)) return false;
      final target = board[tr][tc];
      if (target.isEmpty) return true;
      if (target.toUpperCase() == "K") return false;
      return white ? _isBlack(target) : _isWhite(target);
    }

    if (p == "P") {
      final dir = white ? -1 : 1;
      if (!forAttack) {
        final oneStep = r + dir;
        final startRow = white ? 6 : 1;
        if (_inBounds(oneStep, c) && board[oneStep][c].isEmpty) {
          moves.add(_ChessMove(r, c, oneStep, c));
          final twoStep = r + (2 * dir);
          if (r == startRow && _inBounds(twoStep, c) && board[twoStep][c].isEmpty) {
            moves.add(_ChessMove(r, c, twoStep, c));
          }
        }
      }
      for (final dc in [-1, 1]) {
        final tr = r + dir;
        final tc = c + dc;
        if (!_inBounds(tr, tc)) continue;
        if (forAttack) {
          moves.add(_ChessMove(r, c, tr, tc));
        } else if (canCapture(tr, tc)) {
          moves.add(_ChessMove(r, c, tr, tc));
        }
      }
      return moves;
    }

    if (p == "N") {
      const jumps = [
        (-2, -1), (-2, 1), (-1, -2), (-1, 2),
        (1, -2), (1, 2), (2, -1), (2, 1),
      ];
      for (final (dr, dc) in jumps) {
        final tr = r + dr;
        final tc = c + dc;
        if (forAttack) {
          if (_inBounds(tr, tc)) moves.add(_ChessMove(r, c, tr, tc));
        } else if (canMoveTo(tr, tc)) {
          moves.add(_ChessMove(r, c, tr, tc));
        }
      }
      return moves;
    }

    void slide(List<(int, int)> dirs) {
      for (final (dr, dc) in dirs) {
        int tr = r + dr;
        int tc = c + dc;
        while (_inBounds(tr, tc)) {
          final target = board[tr][tc];
          if (target.isEmpty) {
            moves.add(_ChessMove(r, c, tr, tc));
          } else {
            if (forAttack) {
              moves.add(_ChessMove(r, c, tr, tc));
            } else if (white ? _isBlack(target) : _isWhite(target)) {
              if (target.toUpperCase() != "K") {
                moves.add(_ChessMove(r, c, tr, tc));
              }
            }
            break;
          }
          tr += dr;
          tc += dc;
        }
      }
    }

    if (p == "B") {
      slide([(1, 1), (1, -1), (-1, 1), (-1, -1)]);
      return moves;
    }
    if (p == "R") {
      slide([(1, 0), (-1, 0), (0, 1), (0, -1)]);
      return moves;
    }
    if (p == "Q") {
      slide([(1, 1), (1, -1), (-1, 1), (-1, -1), (1, 0), (-1, 0), (0, 1), (0, -1)]);
      return moves;
    }
    if (p == "K") {
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final tr = r + dr;
          final tc = c + dc;
          if (forAttack) {
            if (_inBounds(tr, tc)) moves.add(_ChessMove(r, c, tr, tc));
          } else if (canMoveTo(tr, tc)) {
            moves.add(_ChessMove(r, c, tr, tc));
          }
        }
      }
      return moves;
    }

    return moves;
  }

  List<_ChessMove> _legalMovesForPiece(List<List<String>> board, int r, int c, {required bool white}) {
    final pseudo = _pseudoMovesForPiece(board, r, c, white: white);
    final legal = <_ChessMove>[];

    for (final m in pseudo) {
      final copy = _cloneBoard(board);
      _applyMoveOnBoard(copy, m);
      if (!_isKingInCheck(copy, white)) {
        legal.add(m);
      }
    }
    return legal;
  }

  List<_ChessMove> _allLegalMoves(bool white) {
    final result = <_ChessMove>[];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = _board[r][c];
        if (piece.isEmpty) continue;
        if (white && _isWhite(piece)) {
          result.addAll(_legalMovesForPiece(_board, r, c, white: true));
        } else if (!white && _isBlack(piece)) {
          result.addAll(_legalMovesForPiece(_board, r, c, white: false));
        }
      }
    }
    return result;
  }

  Widget _pieceWidget(String piece) {
    if (piece.isEmpty) return const SizedBox.shrink();
    final path = _pieceImage[piece];
    if (path == null) return const SizedBox.shrink();
    final bool isBlackPiece = piece == piece.toLowerCase();
    final bool hasBlackVariant = path.endsWith("1.png");
    final Widget image = Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Text(
        piece,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(2),
      child: isBlackPiece && !hasBlackVariant
          ? ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.modulate),
              child: image,
            )
          : image,
    );
  }

  void _onTapSquare(int r, int c) {
    if (_isGameOver || _fatherThinking) return;

    if (_selectedR == null || _selectedC == null) {
      final piece = _board[r][c];
      if (piece.isEmpty || !_isWhite(piece)) return;
      setState(() {
        _selectedR = r;
        _selectedC = c;
        _selectedMoves = _legalMovesForPiece(_board, r, c, white: true);
      });
      return;
    }

    final maybeMove = _selectedMoves.where((m) => m.tr == r && m.tc == c).toList(growable: false);
    if (maybeMove.isEmpty) {
      final piece = _board[r][c];
      if (piece.isNotEmpty && _isWhite(piece)) {
        setState(() {
          _selectedR = r;
          _selectedC = c;
          _selectedMoves = _legalMovesForPiece(_board, r, c, white: true);
        });
      } else {
        setState(() {
          _selectedR = null;
          _selectedC = null;
          _selectedMoves = [];
        });
      }
      return;
    }

    _applyMove(maybeMove.first, whiteMove: true);
  }

  void _applyMove(_ChessMove move, {required bool whiteMove}) {
    final moving = _board[move.fr][move.fc];

    setState(() {
      _applyMoveOnBoard(_board, move);
      _selectedR = null;
      _selectedC = null;
      _selectedMoves = [];
      _status = whiteMove
          ? "Sən daş oynadın. ${widget.personName} növbəsidir."
          : "${widget.personName} daş oynadı. Sənin növbəndir.";
    });

    if (_checkEndState(justMovedWhite: whiteMove)) {
      return;
    }

    if (whiteMove && moving.isNotEmpty) {
      _playFatherMove();
    }
  }

  bool _checkEndState({required bool justMovedWhite}) {
    final sideToMoveIsWhite = !justMovedWhite;
    final sideMoves = _allLegalMoves(sideToMoveIsWhite);
    final sideInCheck = _isKingInCheck(_board, sideToMoveIsWhite);

    if (sideMoves.isEmpty) {
      if (sideInCheck) {
        if (sideToMoveIsWhite) {
          _finishChess("lose", "Şahmat! ${widget.personName} qalib gəldi.");
        } else {
          _finishChess("win", "Şahmat! Sən qalib gəldin.");
        }
      } else {
        _finishChess("draw", "Pat! Oyun bərabərə bitdi.");
      }
      return true;
    }

    if (sideInCheck) {
      setState(() {
        _status = sideToMoveIsWhite
            ? "Sən şah altındasan. Növbə səndədir."
            : "${widget.personName} şah altındadır.";
      });
    }
    return false;
  }

  void _finishChess(String outcome, String status) {
    MiniGameResult built;
    if (outcome == "win") {
      built = MiniGameResult(
        gameName: "Şahmat",
        outcome: "win",
        relationshipDelta: 15,
        happinessDelta: 10,
        logMessage: "${widget.personName} ilə şahmat oynayıb qalib gəldin.",
      );
    } else if (outcome == "lose") {
      built = MiniGameResult(
        gameName: "Şahmat",
        outcome: "lose",
        relationshipDelta: 6,
        happinessDelta: 3,
        logMessage: "${widget.personName} ilə şahmat oynadın, bu dəfə uduzdun.",
      );
    } else {
      built = MiniGameResult(
        gameName: "Şahmat",
        outcome: "draw",
        relationshipDelta: 10,
        happinessDelta: 6,
        logMessage: "${widget.personName} ilə şahmat oyunu heç-heçə bitdi.",
      );
    }

    setState(() {
      _isGameOver = true;
      _fatherThinking = false;
      _result = built;
      _status = status;
    });
  }

  void _playFatherMove() {
    setState(() {
      _fatherThinking = true;
      _status = "${widget.personName} düşünür...";
    });

    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted || _isGameOver) return;

      final moves = _allLegalMoves(false);
      if (moves.isEmpty) {
        _checkEndState(justMovedWhite: true);
        return;
      }

      final mv = moves[_random.nextInt(moves.length)];
      setState(() {
        _fatherThinking = false;
      });
      _applyMove(mv, whiteMove: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Şahmat"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = min(constraints.maxWidth, constraints.maxHeight);
                    return Center(
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                          ),
                          itemCount: 64,
                          itemBuilder: (context, index) {
                            final r = index ~/ 8;
                            final c = index % 8;
                            final piece = _board[r][c];
                            final isLight = (r + c) % 2 == 0;
                            final isSelected = _selectedR == r && _selectedC == c;
                            final isTarget = _selectedMoves.any((m) => m.tr == r && m.tc == c);

                            Color cell = isLight ? const Color(0xFFF0D9B5) : const Color(0xFFB58863);
                            if (isSelected) {
                              cell = Colors.lightBlueAccent;
                            } else if (isTarget) {
                              cell = Colors.greenAccent;
                            }

                            return GestureDetector(
                              onTap: () => _onTapSquare(r, c),
                              child: Container(
                                color: cell,
                                child: Center(child: _pieceWidget(piece)),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isGameOver ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isGameOver && _result != null
                  ? () => Navigator.pop(context, _result)
                  : null,
              child: const Text("Nəticəni təsdiqlə"),
            ),
          ],
        ),
      ),
    );
  }
}

class DominoTile {
  final int a;
  final int b;

  const DominoTile(this.a, this.b);

  int get pipSum => a + b;

  String get label => "[$a|$b]";

  bool matches(int value) => a == value || b == value;

  DominoTile flipped() => DominoTile(b, a);
}

class RealDominoGameScreen extends StatefulWidget {
  final String personName;

  const RealDominoGameScreen({super.key, required this.personName});

  @override
  State<RealDominoGameScreen> createState() => _RealDominoGameScreenState();
}

class _RealDominoGameScreenState extends State<RealDominoGameScreen> {
  final Random _random = Random();
  final List<DominoTile> _playerHand = [];
  final List<DominoTile> _fatherHand = [];
  final List<DominoTile> _boneyard = [];
  final List<DominoTile> _chain = [];

  bool _isPlayerTurn = true;
  bool _isGameOver = false;
  bool _fatherThinking = false;
  int _consecutivePasses = 0;
  final Set<String> _missingDominoAssets = <String>{};
  String _status = "Domino başlayır...";
  MiniGameResult? _result;

  String _dominoAssetPrimary(DominoTile tile) =>
      "assets/gameImages/domino_${tile.a}_${tile.b}.png";

  String _dominoAssetReverse(DominoTile tile) =>
      "assets/gameImages/domino_${tile.b}_${tile.a}.png";

  Widget _dominoAssetWidget(DominoTile tile, {double width = 64, double height = 48}) {
    final primaryPath = _dominoAssetPrimary(tile);
    final reversePath = _dominoAssetReverse(tile);

    final primaryMissing = _missingDominoAssets.contains(primaryPath);
    final reverseMissing = _missingDominoAssets.contains(reversePath);

    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.black12),
    );

    // 1. Both are known to be missing -> show label
    if (primaryMissing && reverseMissing) {
      return Container(
        width: width, height: height, alignment: Alignment.center,
        decoration: decoration,
        child: Text(tile.label, style: const TextStyle(fontSize: 11)),
      );
    }

    // 2. Primary is known to be missing -> try reverse directly (rotated)
    if (primaryMissing) {
      return Container(
        width: width, height: height, decoration: decoration, clipBehavior: Clip.antiAlias,
        child: RotatedBox(
          quarterTurns: 2,
          child: Image.asset(
            reversePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              _markAssetMissing(reversePath);
              return Center(child: Text(tile.label, style: const TextStyle(fontSize: 11)));
            },
          ),
        ),
      );
    }

    // 3. Try primary, with fallback to reverse in errorBuilder
    return Container(
      width: width, height: height, decoration: decoration, clipBehavior: Clip.antiAlias,
      child: Image.asset(
        primaryPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          _markAssetMissing(primaryPath);
          
          if (reversePath != primaryPath && !reverseMissing) {
            return RotatedBox(
              quarterTurns: 2,
              child: Image.asset(
                reversePath,
                fit: BoxFit.contain,
                errorBuilder: (context2, error2, stackTrace2) {
                  _markAssetMissing(reversePath);
                  return Center(child: Text(tile.label, style: const TextStyle(fontSize: 11)));
                },
              ),
            );
          }
          return Center(child: Text(tile.label, style: const TextStyle(fontSize: 11)));
        },
      ),
    );
  }

  void _markAssetMissing(String path) {
    if (!_missingDominoAssets.contains(path)) {
      // Use a post-frame callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _missingDominoAssets.add(path);
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _setupGame();
  }

  void _setupGame() {
    final deck = <DominoTile>[];
    for (int i = 0; i <= 6; i++) {
      for (int j = i; j <= 6; j++) {
        deck.add(DominoTile(i, j));
      }
    }
    deck.shuffle(_random);

    _playerHand.addAll(deck.take(7));
    deck.removeRange(0, 7);
    _fatherHand.addAll(deck.take(7));
    deck.removeRange(0, 7);
    _boneyard.addAll(deck);

    setState(() {
      _status = "Sən başlayırsan. Əlindəki daşlardan birini qoy.";
      _isPlayerTurn = true;
    });
  }

  int get _leftValue => _chain.first.a;
  int get _rightValue => _chain.last.b;

  bool _canPlaceOnLeft(DominoTile t) => _chain.isEmpty || t.matches(_leftValue);
  bool _canPlaceOnRight(DominoTile t) => _chain.isEmpty || t.matches(_rightValue);

  List<DominoTile> _playableTiles(List<DominoTile> hand) {
    if (_chain.isEmpty) return List<DominoTile>.from(hand);
    return hand.where((t) => _canPlaceOnLeft(t) || _canPlaceOnRight(t)).toList();
  }

  void _playerTapTile(DominoTile tile) async {
    if (!_isPlayerTurn || _isGameOver || _fatherThinking) return;
    if (!_playerHand.contains(tile)) return;
    if (!_canPlaceOnLeft(tile) && !_canPlaceOnRight(tile)) return;

    if (_chain.isEmpty) {
      setState(() {
        _playerHand.remove(tile);
        _chain.add(tile);
        _consecutivePasses = 0;
        _status = "Sən ${tile.label} qoydun.";
      });
      _afterPlayerMove();
      return;
    }

    final bool canLeft = _canPlaceOnLeft(tile);
    final bool canRight = _canPlaceOnRight(tile);
    String side = "right";

    if (canLeft && canRight) {
      final selected = await showModalBottomSheet<String>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.keyboard_double_arrow_left),
                  title: const Text("Sola qoy"),
                  onTap: () => Navigator.pop(context, "left"),
                ),
                ListTile(
                  leading: const Icon(Icons.keyboard_double_arrow_right),
                  title: const Text("Sağa qoy"),
                  onTap: () => Navigator.pop(context, "right"),
                ),
              ],
            ),
          );
        },
      );
      if (selected == null) return;
      side = selected;
    } else if (canLeft) {
      side = "left";
    }

    _placeTileFromPlayer(tile, side);
    _afterPlayerMove();
  }

  void _placeTileFromPlayer(DominoTile tile, String side) {
    final placed = _orientedTile(tile, side);
    setState(() {
      _playerHand.remove(tile);
      if (side == "left") {
        _chain.insert(0, placed);
      } else {
        _chain.add(placed);
      }
      _consecutivePasses = 0;
      _status = "Sən ${tile.label} qoydun.";
    });
  }

  DominoTile _orientedTile(DominoTile tile, String side) {
    if (_chain.isEmpty) return tile;

    if (side == "left") {
      // New tile right side should match current left value.
      return tile.b == _leftValue ? tile : tile.flipped();
    }
    // New tile left side should match current right value.
    return tile.a == _rightValue ? tile : tile.flipped();
  }

  void _afterPlayerMove() {
    if (_checkAndFinishIfNeeded()) return;
    setState(() {
      _isPlayerTurn = false;
      _fatherThinking = true;
      _status = "${widget.personName} düşünür...";
    });
    Future.delayed(const Duration(milliseconds: 650), _fatherMove);
  }

  void _playerDraw() {
    if (!_isPlayerTurn || _isGameOver || _fatherThinking) return;
    if (_boneyard.isEmpty) return;

    setState(() {
      _playerHand.add(_boneyard.removeLast());
      _status = "Bir daş çəkdin.";
    });
  }

  void _playerPass() {
    if (!_isPlayerTurn || _isGameOver || _fatherThinking) return;
    if (_playableTiles(_playerHand).isNotEmpty) return;

    setState(() {
      _consecutivePasses++;
      _isPlayerTurn = false;
      _fatherThinking = true;
      _status = "Sən keçdin. ${widget.personName} növbəsidir.";
    });
    if (_checkAndFinishIfNeeded()) return;
    Future.delayed(const Duration(milliseconds: 650), _fatherMove);
  }

  void _fatherMove() {
    if (!mounted || _isGameOver) return;

    while (_playableTiles(_fatherHand).isEmpty && _boneyard.isNotEmpty) {
      _fatherHand.add(_boneyard.removeLast());
    }

    final playable = _playableTiles(_fatherHand);
    if (playable.isEmpty) {
      setState(() {
        _consecutivePasses++;
        _isPlayerTurn = true;
        _fatherThinking = false;
        _status = "${widget.personName} keçdi. Sənin növbəndir.";
      });
      _checkAndFinishIfNeeded();
      return;
    }

    final tile = playable[_random.nextInt(playable.length)];
    String side = "right";
    final canLeft = _canPlaceOnLeft(tile);
    final canRight = _canPlaceOnRight(tile);
    if (canLeft && canRight) {
      side = _random.nextBool() ? "left" : "right";
    } else if (canLeft) {
      side = "left";
    }

    final placed = _orientedTile(tile, side);
    setState(() {
      _fatherHand.remove(tile);
      if (side == "left") {
        _chain.insert(0, placed);
      } else {
        _chain.add(placed);
      }
      _consecutivePasses = 0;
      _isPlayerTurn = true;
      _fatherThinking = false;
      _status = "${widget.personName} ${tile.label} qoydu. Sənin növbəndir.";
    });
    _checkAndFinishIfNeeded();
  }

  bool _checkAndFinishIfNeeded() {
    if (_isGameOver) return true;

    if (_playerHand.isEmpty) {
      _finishWithOutcome("win");
      return true;
    }
    if (_fatherHand.isEmpty) {
      _finishWithOutcome("lose");
      return true;
    }

    final noMovesAndNoStock = _boneyard.isEmpty &&
        _playableTiles(_playerHand).isEmpty &&
        _playableTiles(_fatherHand).isEmpty;
    if (_consecutivePasses >= 2 || noMovesAndNoStock) {
      final playerSum = _playerHand.fold<int>(0, (sum, t) => sum + t.pipSum);
      final fatherSum = _fatherHand.fold<int>(0, (sum, t) => sum + t.pipSum);
      if (playerSum < fatherSum) {
        _finishWithOutcome("win");
      } else if (playerSum > fatherSum) {
        _finishWithOutcome("lose");
      } else {
        _finishWithOutcome("draw");
      }
      return true;
    }
    return false;
  }

  void _finishWithOutcome(String outcome) {
    MiniGameResult built;
    if (outcome == "win") {
      built = MiniGameResult(
        gameName: "Domino",
        outcome: "win",
        relationshipDelta: 14,
        happinessDelta: 9,
        logMessage: "${widget.personName} ilə domino oynayıb qalib gəldin.",
      );
    } else if (outcome == "lose") {
      built = MiniGameResult(
        gameName: "Domino",
        outcome: "lose",
        relationshipDelta: 5,
        happinessDelta: 2,
        logMessage: "${widget.personName} ilə domino oynadın, bu dəfə uduzdun.",
      );
    } else {
      built = MiniGameResult(
        gameName: "Domino",
        outcome: "draw",
        relationshipDelta: 9,
        happinessDelta: 5,
        logMessage: "${widget.personName} ilə domino oyunu heç-heçə bitdi.",
      );
    }

    setState(() {
      _isGameOver = true;
      _fatherThinking = false;
      _isPlayerTurn = false;
      _result = built;
      _status = "Oyun bitdi.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final playableCount = _playableTiles(_playerHand).length;
    final bool canDraw = _isPlayerTurn && !_isGameOver && _boneyard.isNotEmpty;
    final bool canPass = _isPlayerTurn && !_isGameOver && playableCount == 0 && _boneyard.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Domino"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/gameImages/table.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: Colors.white.withValues(alpha: 0.85),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Colors.white.withValues(alpha: 0.85),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${widget.personName} daş: ${_fatherHand.length}"),
                      Text("Daş qutusu: ${_boneyard.length}"),
                      Text("Səndə: ${_playerHand.length}"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Colors.white.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _chain.isEmpty
                      ? const Text("Masa boşdur. İlk daşı sən qoy.")
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _chain
                              .map((t) => _dominoAssetWidget(t))
                              .toList(growable: false),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  elevation: 0,
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _playerHand.map((tile) {
                          final playable = _canPlaceOnLeft(tile) || _canPlaceOnRight(tile) || _chain.isEmpty;
                          final enabled = _isPlayerTurn && !_isGameOver && playable && !_fatherThinking;
                          return InkWell(
                            onTap: enabled ? () => _playerTapTile(tile) : null,
                            borderRadius: BorderRadius.circular(10),
                            child: Opacity(
                              opacity: enabled ? 1.0 : 0.45,
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  _dominoAssetWidget(tile, width: 72, height: 52),
                                  if (playable)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 1, right: 1),
                                      child: Icon(Icons.check_circle, size: 14, color: Colors.green),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(growable: false),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canDraw ? _playerDraw : null,
                      child: const Text("Daş çək"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canPass ? _playerPass : null,
                      child: const Text("Keç"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isGameOver ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isGameOver && _result != null
                    ? () => Navigator.pop(context, _result)
                    : null,
                child: const Text("Nəticəni təsdiqlə"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickBoardGameScreen extends StatefulWidget {
  final String personName;
  final String gameName;

  const QuickBoardGameScreen({
    super.key,
    required this.personName,
    required this.gameName,
  });

  @override
  State<QuickBoardGameScreen> createState() => _QuickBoardGameScreenState();
}

class _QuickBoardGameScreenState extends State<QuickBoardGameScreen> {
  final Random _random = Random();
  int _round = 1;
  int _myScore = 0;
  int _theirScore = 0;
  static const int _maxRounds = 5;
  bool _finished = false;

  int get _baseWinChance {
    switch (widget.gameName) {
      case "Nərd":
        return 48;
      default:
        return 50;
    }
  }

  void _playRound() {
    if (_finished) return;
    final bool iWin = _random.nextInt(100) < _baseWinChance;

    setState(() {
      if (iWin) {
        _myScore++;
      } else {
        _theirScore++;
      }

      if (_round >= _maxRounds) {
        _finished = true;
      } else {
        _round++;
      }
    });
  }

  MiniGameResult _buildResult() {
    if (_myScore > _theirScore) {
      return MiniGameResult(
        gameName: widget.gameName,
        outcome: "win",
        relationshipDelta: 12,
        happinessDelta: 8,
        logMessage: "${widget.personName} ilə ${widget.gameName} oynayıb qalib gəldin.",
      );
    }
    if (_myScore == _theirScore) {
      return MiniGameResult(
        gameName: widget.gameName,
        outcome: "draw",
        relationshipDelta: 7,
        happinessDelta: 5,
        logMessage: "${widget.personName} ilə ${widget.gameName} oyunu heç-heçə bitdi.",
      );
    }
    return MiniGameResult(
      gameName: widget.gameName,
      outcome: "lose",
      relationshipDelta: 3,
      happinessDelta: 2,
      logMessage: "${widget.personName} ilə ${widget.gameName} oynadın, bu dəfə uduzdun.",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.gameName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text("Raund: $_round / $_maxRounds", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _scoreBox("Sen", _myScore, Colors.blueAccent),
                        _scoreBox(widget.personName, _theirScore, Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _finished ? Colors.green : Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                if (!_finished) {
                  _playRound();
                  return;
                }

                Navigator.pop(context, _buildResult());
              },
              child: Text(_finished ? "Nəticəni təsdiqlə" : "Raund oyna"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBox(String title, int score, Color color) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            "$score",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
