from flask import Flask, render_template, request, jsonify
import copy
import random

app = Flask(__name__)

def check_win(board, marker):
    for i in range(3):
        if all(cell == marker for cell in board[i]):
            return True
        if all(row[i] == marker for row in board):
            return True
    if all(board[i][i] == marker for i in range(3)) or all(board[i][2 - i] == marker for i in range(3)):
        return True
    return False

def check_draw(board):
    return all(cell != '' for row in board for cell in row)

def get_ai_move(board, difficulty):
    if difficulty == 'easy':
        return random.choice([(r, c) for r in range(3) for c in range(3) if board[r][c] == ''])
    elif difficulty == 'medium':
        return get_medium_ai_move(board)
    else:
        return get_minimax_move(board)

def get_medium_ai_move(board, ai='O', human='X'):
    for r in range(3):
        for c in range(3):
            if board[r][c] == '':
                temp = copy.deepcopy(board)
                temp[r][c] = human
                if check_win(temp, human):
                    return r, c
    if board[1][1] == '':
        return 1, 1
    for r, c in [(0,0), (0,2), (2,0), (2,2)]:
        if board[r][c] == '':
            return r, c
    for r, c in [(0,1), (1,0), (1,2), (2,1)]:
        if board[r][c] == '':
            return r, c
    return random.choice([(r, c) for r in range(3) for c in range(3) if board[r][c] == ''])

def get_minimax_move(board, ai='O', human='X'):
    def minimax(b, depth, is_max):
        if check_win(b, ai):
            return 10 - depth
        if check_win(b, human):
            return depth - 10
        if check_draw(b):
            return 0
        if is_max:
            best = -float('inf')
            for r in range(3):
                for c in range(3):
                    if b[r][c] == '':
                        b[r][c] = ai
                        score = minimax(b, depth + 1, False)
                        b[r][c] = ''
                        best = max(score, best)
            return best
        else:
            best = float('inf')
            for r in range(3):
                for c in range(3):
                    if b[r][c] == '':
                        b[r][c] = human
                        score = minimax(b, depth + 1, True)
                        b[r][c] = ''
                        best = min(score, best)
            return best

    best_score = -float('inf')
    move = None
    for r in range(3):
        for c in range(3):
            if board[r][c] == '':
                board[r][c] = ai
                score = minimax(board, 0, False)
                board[r][c] = ''
                if score > best_score:
                    best_score = score
                    move = (r, c)
    return move

@app.route("/")
def home():
    return render_template("index.html")

@app.route("/move", methods=["POST"])
def move():
    data = request.json
    board = data["board"]
    difficulty = data["difficulty"]
    move = get_ai_move(board, difficulty)
    r, c = move
    return jsonify({"row": r, "col": c})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5050)