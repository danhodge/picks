import { Data, Game, GameOutcome, isCompleted, Participant, scoreForTeam, Team } from "./App";

export interface GameProps {
  data: Data;
  game: Game;
}

export interface ResultProps {
  game: Game;
  outcome: GameOutcome | undefined;
}

export interface PicksProps {
  game: Game;
  picksFor: Map<number, PickStats>;
}

class PickStats {
  readonly picks: Map<string, number>;

  constructor() {
    this.picks = new Map<string, number>();
  }

  totalPicks(): number {
    return this.picks.size;
  }

  totalPoints(): number {
    var total = 0;
    this.picks.forEach((val: number) => total += val);

    return total;
  }

  update(name: string, points: number): void {
    this.picks.set(name, points);
  }
}

const Result = (props: ResultProps) => {
  return isCompleted(props.outcome) ?
    <div>Winner: {props.outcome?.pointsAwardedTo.name}</div > : <div>Incomplete</div>;
};


export interface PickGroupProps {
  team: Team;
  stats: PickStats;
}

const PickGroup = (props: PickGroupProps) => {
  return <div>
    <div>
      <div>
        <>
          {props.team.name} {props.stats.totalPicks()} picks, {props.stats.totalPoints()} points
        </>
      </div>
    </div>
  </div>;
};

const Picks = (props: PicksProps) => {
  const sections = Array.from(props.picksFor.entries()).map((val: [number, PickStats]) => {
    const [id, stats] = val;
    const team = props.game.home.id === id ? props.game.home : props.game.visitor;
    const groupId = `${props.game.id}_${team.id}`;
    return <PickGroup key={groupId} team={team} stats={stats} />;
  });

  return <div>{sections}</div>;
}

const GameComponent = (props: GameProps) => {
  const outcome = props.data.results.get(props.game.id);
  //props.data.participants.get(1)?.picks

  const picksFor = new Map<number, PickStats>();

  props.data.participants.forEach((participant: Participant) => {
    const pick = participant.picks.get(props.game.id);
    if (pick) {
      var stats = picksFor.get(pick.team.id);
      if (!stats) {
        stats = new PickStats();
        picksFor.set(pick.team.id, stats);
      }
      stats.update(participant.name, pick.points);
    }
  });

  //const medianPick = medianPickForGame(props.data, props.game);
  //const winningPct = (isCompleted(props.game) && props.game.totalPointsWon) ? Math.round((props.game.totalPointsWon / props.game.totalPoints) * 100) : 0;
  //const gamesByPointsWagered = props.data.games.sort((g1, g2) => g2.totalPoints - g1.totalPoints);
  //const wageredIndex = gamesByPointsWagered.indexOf(props.game);
  // const gamesByPointsWon = props.data.games.sort((g1, g2) => {
  //   if (g2.totalPointsWon && g1.totalPointsWon) {
  //     return g2.totalPointsWon - g1.totalPointsWon;
  //   } else {
  //     return -999999;
  //   }
  // });
  //const pointsWonIndex = gamesByPointsWon.indexOf(props.game);

  return <div>
    <div>
      {props.game.name}
    </div>
    <div>
      {props.game.visitor.name} - {scoreForTeam(outcome, props.game.visitor) || "unknown"}
    </div>
    at
    <div>
      {props.game.home.name} - {scoreForTeam(outcome, props.game.home) || "unknown"
      }
    </div >
    {/* <div>Median Pick</div><div>{medianPick.team} - {medianPick.points}</div> */}
    <Result game={props.game} outcome={outcome} />
    <Picks game={props.game} picksFor={picksFor} />
    {/* <div>Total Points Wagered - {props.game.totalPoints} (#{wageredIndex + 1})</div>
    {isCompleted(props.game) ? <div>Total Points Won - {props.game.totalPointsWon} (#{pointsWonIndex + 1})</div> : <div></div>}
    {isCompleted(props.game) ? <div>Winning Pct - {winningPct}%</div> : <div></div>} */}
  </div>;
};

export default GameComponent;