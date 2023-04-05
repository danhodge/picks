import { Data, Game, Participant, Pick } from "./App";
import { Link } from "wouter";

export interface ParticipantComponentProps {
  data: Data;
  participant: Participant;
}

export const ParticipantComponent = (props: ParticipantComponentProps) => {
  const rowBg = ["bg-blue-300", "bg-blue-400"];
  const results = Array.from(props.participant.picks.entries()).map((val: [number, Pick], idx: number) => {
    const [_, pick] = val;
    const outcome = props.data.results.get(pick.game.id);

    return <div className={"grid grid-cols-7 " + rowBg[idx % 2]}>
      <div><Link href={"/games/" + pick.game.id}>{pick.game.name}</Link></div>
      <div>{pick.team.name}</div>
      <div></div>
      <div className="font-semibold">{(outcome?.pointsAwardedTo === pick.team) ? pick.points : ""}</div>
      <div className="font-thin">{(outcome?.pointsAwardedTo !== pick.team) ? pick.points : ""}</div>
      <div>{pick.totalPoints}</div>
      <div>{place(props.data.participants, props.participant, pick.game, pick.totalPoints)}</div>
    </div>;
  });
  return <div>
    <div className="pb-4 pl-2 pt-2 font-semibold">{props.participant.name}</div>
    <div className="p-2 bg-blue-300 rounded-lg w-4/5">
      <div className="grid grid-cols-7 font-semibold border-b border-slate-500">
        <div>Game</div>
        <div>Team</div>
        <div></div>
        <div>Points Won</div>
        <div>Points Lost</div>
        <div>Total</div>
        <div>Place</div>
      </div>
      {results}
    </div>
  </div >;
};

interface ParticipantPoints {
  participant: Participant;
  points: number;
};

const place = (participants: Map<number, Participant>, participant: Participant, game: Game, totalPoints: number) => {
  const sorter = (a: ParticipantPoints, b: ParticipantPoints) => {
    const diff = b.points - a.points;
    if (diff === 0) {
      return a.participant.name < b.participant.name ? -1 : 1;
    }
    return diff;
  };

  const results = Array.from(participants.values()).map((val: Participant) => {
    const pick = val.picks.get(game.id);
    if (pick) {
      // TODO: should also take points lost into account
      return { participant: val, points: pick.totalPoints };
    } else {
      return { participant: val, points: 0 };
    }
  }).sort(sorter);

  return results.findIndex((val: ParticipantPoints) => val.participant === participant) + 1;
};

