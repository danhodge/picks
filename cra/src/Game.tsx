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

export interface PickGroupProps {
  team: Team;
  stats: PickStats;
}

const PickGroup = (props: PickGroupProps) => {
  const sorter = (a: [string, number], b: [string, number]) => {
    const [aName, aPoints] = a;
    const [bName, bPoints] = b;
    const diff = bPoints - aPoints; // sort by points descending
    if (diff === 0) {
      return aName < bName ? -1 : 1; // sort by names ascending
    } else {
      return diff;
    }
  };
  const rows = Array.from(props.stats.picks.entries()).sort(sorter).map((val: [string, number]) => {
    const [name, points] = val;
    return <div key={name}><span>{name}: {points}</span></div>
  });

  return <div className="pt-6">
    <div>
      <div>
        <>
          {props.team.name} {props.stats.totalPicks()} picks, {props.stats.totalPoints()} points
        </>
      </div>
      <div className="grid grid-cols-6 gap-2 p-3">
        {rows}
      </div >
    </div >
  </div >;
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

  return <div className="bg-slate-300 container mx-auto">
    <div className="pb-5">
      <p className="font-semibold text-lg">{props.game.name}</p>
    </div>
    <div className="w-80 rounded-lg border-2 border-slate-800 grid grid-cols-5 gap-2 p-3">
      <TeamScore team={props.game.visitor} outcome={outcome} />
      <TeamScore team={props.game.home} outcome={outcome} />
    </div>
    <Picks game={props.game} picksFor={picksFor} />
    {/* <div>Total Points Wagered - {props.game.totalPoints} (#{wageredIndex + 1})</div>
    {isCompleted(props.game) ? <div>Total Points Won - {props.game.totalPointsWon} (#{pointsWonIndex + 1})</div> : <div></div>}
    {isCompleted(props.game) ? <div>Winning Pct - {winningPct}%</div> : <div></div>} */}
  </div >;
};


export interface TeamScoreProps {
  team: Team;
  outcome: GameOutcome | undefined;
}

const TeamScore = (props: TeamScoreProps) => {
  return (props.outcome?.pointsAwardedTo === props.team) ?
    <>
      <div className="col-span-4 font-semibold">{props.team.name}</div>
      <div className="font-semibold">{scoreForTeam(props.outcome, props.team) || " unknown"}</div>
    </> :
    <>
      <div className="col-span-4">{props.team.name}</div>
      <div>{scoreForTeam(props.outcome, props.team) || " unknown"}</div>
    </>;
}

export default GameComponent;