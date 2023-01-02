import { Data, Game, isCompleted, medianPickForGame, scoreForTeam, winner } from "./App";

export interface GameProps {
  data: Data;
  game: Game;
}

export interface ResultProps {
  game: Game;
}

const Result = (props: ResultProps) => {
  return isCompleted(props.game) ?
    <div>Winner: {winner(props.game)?.name}</div > : <div>Incomplete</div>;
};

const GameComponent = (props: GameProps) => {
  const medianPick = medianPickForGame(props.data, props.game);
  const winningPct = (isCompleted(props.game) && props.game.totalPointsWon) ? Math.round((props.game.totalPointsWon / props.game.totalPoints) * 100) : 0;
  const gamesByPointsWagered = props.data.games.sort((g1, g2) => g2.totalPoints - g1.totalPoints);
  const wageredIndex = gamesByPointsWagered.indexOf(props.game);
  const gamesByPointsWon = props.data.games.sort((g1, g2) => {
    if (g2.totalPointsWon && g1.totalPointsWon) {
      return g2.totalPointsWon - g1.totalPointsWon;
    } else {
      return -999999;
    }
  });
  const pointsWonIndex = gamesByPointsWon.indexOf(props.game);

  return <div>
    <div>
      {props.game.name}
    </div>
    <div>
      {props.game.visitor.name} - {scoreForTeam(props.game, props.game.visitor) || "unknown"}
    </div>
    at
    <div>
      {props.game.home.name} - {scoreForTeam(props.game, props.game.home) || "unknown"}
    </div>
    <div>Median Pick</div><div>{medianPick.team} - {medianPick.points}</div>
    <Result game={props.game} />
    <div>Total Points Wagered - {props.game.totalPoints} (#{wageredIndex + 1})</div>
    {isCompleted(props.game) ? <div>Total Points Won - {props.game.totalPointsWon} (#{pointsWonIndex + 1})</div> : <div></div>}
    {isCompleted(props.game) ? <div>Winning Pct - {winningPct}%</div> : <div></div>}
  </div>;
};

export default GameComponent;