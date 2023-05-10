import { Data, Game, GameOutcome, isCompleted, Participant, scoreForTeam, Season, Team } from "./App";
import { Link } from "wouter";

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
  season: Season;
  picksFor: Map<number, PickStats>;
}

class PickStats {
  readonly picks: Map<Participant, number>;

  constructor() {
    this.picks = new Map<Participant, number>();
  }

  totalPicks(): number {
    return this.picks.size;
  }

  totalPoints(): number {
    var total = 0;
    this.picks.forEach((val: number) => total += val);

    return total;
  }

  // TODO: store total points so it can be displayed and used for sorting
  update(participant: Participant, points: number, totalPoints: number): void {
    this.picks.set(participant, points);
  }
}

export interface PickGroupProps {
  team: Team;
  stats: PickStats;
  game: Game;
  season: Season;
}

const PickGroup = (props: PickGroupProps) => {
  const sorter = (a: [Participant, number], b: [Participant, number]) => {
    const [aName, aPoints] = a;
    const [bName, bPoints] = b;
    const diff = bPoints - aPoints; // sort by points descending
    if (diff === 0) {
      return aName.name < bName.name ? -1 : 1; // sort by names ascending
    } else {
      return diff;
    }
  };

  const rowBg = ["bg-slate-50", "bg-white"];
  const rows = Array.from(props.stats.picks.entries()).sort(sorter).map((val: [Participant, number], idx: number) => {
    const [participant, points] = val;
    const rowIdx = Math.floor(idx / 4) % 2;
    return <>
      <div className={rowBg[rowIdx]} key={participant.name + "_name"}><Link href={"/" + props.season.path + "/participants/" + participant.id}>{participant.name}</Link></div>
      <div className={rowBg[rowIdx] + " font-thin"} key={participant.name + "_points"}>{points}</div>
    </>
  });

  return <div className="pt-6">
    <div>
      <div className="text-lg">
        <>
          {props.team.name} <span className="font-extralight">{props.stats.totalPicks()} picks {props.stats.totalPoints()} points</span>
        </>
      </div>
      <div className="bg-slate-50 rounded-lg grid grid-cols-8 gap-y-2 p-3">
        {rows}
      </div>
    </div>
  </div>;
};

const pickVisitor = (game: Game) => {
  return game.prevVisitor ? game.prevVisitor : game.visitor;
};

const pickHome = (game: Game) => {
  return game.prevHome ? game.prevHome : game.home;
};

const Picks = (props: PicksProps) => {
  const sections = Array.from(props.picksFor.entries()).map((val: [number, PickStats]) => {
    const [id, stats] = val;
    const team = pickHome(props.game).id === id ? pickHome(props.game) : pickVisitor(props.game);
    const groupId = `${props.game.id}_${team.id}`;
    return <PickGroup key={groupId} team={team} game={props.game} stats={stats} season={props.season} />;
  });

  return <div>
    <div>{sections}</div>
  </div>;
}

interface GameResultProps {
  game: Game;
  outcome: GameOutcome;
}

const FinalScore = (props: GameResultProps) => {
  const disclaimer = (props.game.prevHome) ?
    <div className="font-light pb-6"><span className="underline">{props.game.home.name}</span> replaced <span className="underline">{props.game.prevHome.name}</span></div> :
    (props.game.prevVisitor) ?
      <div className="font-light pb-6"><span className="underline">{props.game.visitor.name}</span> replaced <span className="underline">{props.game.prevVisitor.name}</span></div> :
      <div />;


  return <div className="w-80">
    <div className="bg-gray-50 rounded-lg border-2 border-slate-600 grid grid-cols-5 gap-2 p-3">
      <TeamScore team={props.game.visitor} outcome={props.outcome} />
      <TeamScore team={props.game.home} outcome={props.outcome} />
    </div>
    <div className="mb-8 text-right font-semibold text-md italic pr-3">final</div>
    {disclaimer}
  </div>;
}

const Forfeit = (props: GameResultProps) => {
  return <div className="pb-6 font-light">
    Game forfeited by <span className="underline">{props.outcome.forfeitedBy?.name}</span>,
    points awarded to <span className="underline font-semibold">{props.outcome.pointsAwardedTo?.name}</span>
  </div>
}

const GameComponent = (props: GameProps) => {
  const outcome = props.data.results.get(props.game.id) || { status: "incomplete" };

  // populate the picksFor map to ensure that the visiting team is always first
  const picksFor = new Map<number, PickStats>();
  picksFor.set(pickVisitor(props.game).id, new PickStats());
  picksFor.set(pickHome(props.game).id, new PickStats());

  props.data.participants.forEach((participant: Participant) => {
    const pick = participant.picks.get(props.game.id);
    if (pick) {
      var stats = picksFor.get(pick.team.id);
      if (!stats) {
        stats = new PickStats();
        picksFor.set(pick.team.id, stats);
      }
      stats.update(participant, pick.points, pick.totalPoints);
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

  const time = new Date(Date.parse(props.game.time)).toLocaleDateString("en-US", { weekday: 'short', month: "short", day: "numeric", hour: "numeric", minute: "numeric" });

  // TODO: what to display when a team changes?
  return <div className="bg-yellow-100 container mx-auto pt-10">
    <div className="pb-5">
      <p className="font-semibold text-xl">{props.game.name}</p>
      <p className="font-thin text-sm">
        <span>{props.game.location}</span>
        <span className="p-4">{time}</span>
      </p>
    </div>
    <div className="w-1/2">
      {outcome.status === "completed" ?
        <FinalScore game={props.game} outcome={outcome} /> :
        outcome.status === "forfeited" ? <Forfeit game={props.game} outcome={outcome} /> : <></>}
    </div>
    <Picks game={props.game} picksFor={picksFor} season={props.data.season} />
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