import { Data, GameData, medianPickForGame } from "./App";

export interface GameProps {
  data: Data;
  game: GameData;
}

export interface ResultProps {
  game: GameData;
}

const Result = (props: ResultProps) => {
  return props.game.completed() ?
    <div>Winner: {props.game.winner()}</div> : <div>Incomplete</div>;
};

const Game = (props: GameProps) => {
  const medianPick = medianPickForGame(props.data, props.game);
  return <div>
    <div>
      {props.game.name}
    </div>
    <div>
      {props.game.visitor.name} - {props.game.visitor.score}
    </div>
    at
    <div>
      {props.game.home.name} - {props.game.home.score}
    </div>
    <div>Median Pick</div><div>{medianPick.team} - {medianPick.points}</div>
    <Result game={props.game} />
  </div>;
};

export default Game;