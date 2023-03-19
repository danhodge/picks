import { timeStamp } from 'console';
import React, { useEffect, useState } from 'react';
import { QueryClient, QueryClientProvider, useQuery } from 'react-query';
import internal from 'stream';
import { TemplateExpression, textChangeRangeIsUnchanged } from 'typescript';
import './App.css';
import GameComponent from './Game';

/*export interface TeamWithScore {
  name: string;
  score?: number;
}

const loadTeamWithScore = (data: any) => {
  const team: TeamWithScore = { name: data.name };
  if (data.score !== "") {
    team.score = parseInt(data.score);
  }

  return team;
};*/

export interface Game {
  id: number;
  name: string;
  location: string;
  time: string;
  visitor: Team;
  home: Team;
  //scores: Array<FinalScore>;
  //totalPoints: number;
  //totalPointsWon?: number;
};

export interface GameOutcome {
  status: string;
  pointsAwardedTo: Team;
  finalScores: Map<number, number>;
};

export interface Team {
  id: number;
  name: string;
};

export interface FinalScore {
  game: Game;
  team: Team;
  score: number;
};

export interface Pick {
  game: Game;
  team: Team;
  points: number;
  totalPoints: number; // the total number of points this participant has earned (including this pick)
};

export interface Participant {
  name: string;
  tieBreaker: number;
  picks: Map<number, Pick>;
}

export interface Score {
  pointsWon: number;
  pointsLost: number;
  pointsRemaining: number;
  scoringAvg: number;
  wins: number;
  losses: number;
}

export interface Data {
  games: Map<number, Game>;
  participants: Map<number, Participant>;
  results: Map<number, GameOutcome>;
}

const unknownGame = () => {
  return {} as Game;
}

const loadGame = (data: any, id: number, teams: Map<number, Team>) => {
  const visitor = teams.get(data.visiting_team_id);
  const home = teams.get(data.home_team_id);
  if (!visitor || !home) {
    return undefined;
  }

  const game: Game = {
    id: id,
    name: data.name,
    location: data.location,
    time: data.time,
    visitor: visitor,
    home: home
  };
  // loadScores(game, game.visitor, data.visitor);
  // loadScores(game, game.home, data.home);

  return game;
};

// const loadTeam = (data: any) => {
//   const team: Team = { name: data.name };
//   return team;
// };

// const loadScores = (game: Game, team: Team, data: any) => {
//   if (data.score !== "") {
//     const score: FinalScore = {
//       game: game,
//       team: team,
//       score: parseInt(data.score)
//     };
//     //game.scores.push(score);
//   }
// }

const loadTeams = (data: any) => {
  const teams = new Map<number, Team>();
  for (const idStr in data) {
    const id = parseInt(idStr);
    teams.set(id, { id: id, name: data[id] });
  }
  return teams;
}

const loadGames = (data: any, teams: Map<number, Team>) => {
  const games = new Map<number, Game>();
  for (const idStr in data) {
    const id = parseInt(idStr);
    const game = loadGame(data[id], id, teams);
    if (game) {
      games.set(id, game);
    }
  }

  return games;
}

const loadResults = (data: any, teams: Map<number, Team>, games: Map<number, Game>) => {
  const results = new Map<number, GameOutcome>();
  for (const idStr in data) {
    const id = parseInt(idStr);
    const game = games.get(id);
    const winner = teams.get(data[id].points_awarded_to);
    const scores = new Map<number, number>();
    for (const teamIdStr in data[id].final_scores) {
      const team = teams.get(parseInt(teamIdStr));
      if (team) {
        scores.set(team.id, parseInt(data[id].final_scores[teamIdStr]));
      }
    }

    if (game && winner && scores.size === 2) {
      const outcome: GameOutcome = {
        status: data[id].status,
        pointsAwardedTo: winner,
        finalScores: scores
      };
      results.set(id, outcome);
    }
  }

  return results;
}

const loadParticipants = (data: any, games: Map<number, Game>, results: Map<number, GameOutcome>) => {
  const participants = new Map<number, Participant>();
  for (const idStr in data) {
    const id = parseInt(idStr);
    participants.set(id, loadParticipant(data[id], games, results));
  }

  return participants;
}

const loadPick = (data: any, game: Game | undefined, totalPoints: number) => {
  if (!game) {
    return undefined;
  }

  const team = [game.home, game.visitor].find((team: Team) => team.id === data.team_id);
  if (team) {
    return { game: game, team: team, points: data.points, totalPoints: totalPoints };
  } else {
    return undefined;
  }
}

const loadParticipant = (data: any, games: Map<number, Game>, results: Map<number, GameOutcome>) => {
  const picks = new Map<number, Pick>();
  const participant: Participant = {
    name: data.name,
    tieBreaker: data.tiebreaker,
    picks: picks
  };
  var pointTotal = 0;
  for (const gameIdStr in data.picks) {
    const gameId = parseInt(gameIdStr);
    const game = games.get(gameId);
    const pick = loadPick(data.picks[gameId], game, pointTotal);

    if (game && pick) {
      const outcome = results.get(game.id);
      if (outcome && outcome.status === "completed" && outcome.pointsAwardedTo === pick.team) {
        pointTotal += pick.points;
        pick.totalPoints = pointTotal;
      }
      picks.set(gameId, pick);
    }
  }

  return participant;
};

const loadScores = (data: any, participants: Map<number, Participant>) => {
  // load Score objects, attach to Participant
  return 1;
};

// const reconcile = (games: Array<Game>, participants: Array<Participant>) => {
//   games.forEach(game => {
//     const allPicks = participants.flatMap(p => p.picks);
//     const gamePicks = allPicks.filter(pick => pick.game === game);
//     game.totalPoints = gamePicks.reduce((acc, cur) => acc + cur.points, 0);
//     if (isCompleted(game)) {
//       const winning = winner(game);
//       console.log(`Reconciling for winning team ${winning && winning.name}`);
//       game.totalPointsWon = gamePicks.reduce((acc, cur) => acc + (cur.team === winning ? cur.points : 0), 0);
//     }
//   });
// }

export const isCompleted = (outcome: GameOutcome | undefined) => {
  if (!outcome) {
    return undefined;
  }
  return outcome.status === "completed";
};

export const scoreForTeam = (outcome: GameOutcome | undefined, targetTeam: Team) => {
  if (!outcome) {
    return undefined;
  }
  return outcome.finalScores.get(targetTeam.id);
};

// TODO: turn into a game result (win, loss, tie, etc)?
// export const winner = (game: Game) => {
//   if (!isCompleted(game)) {
//     return undefined;
//   }
//   const visitorScore = scoreForTeam(game, game.visitor);
//   const homeScore = scoreForTeam(game, game.home);

//   if (visitorScore && homeScore && visitorScore > homeScore) {
//     return game.visitor;
//   } else if (visitorScore && homeScore && homeScore > visitorScore) {
//     return game.home;
//   } else {
//     return undefined;
//   }
// };


/*export interface GameData {
  name: string;
  location: string;
  time: string;
  visitor: TeamWithScore;
  home: TeamWithScore;
  completed(): boolean;
  winner(): string | undefined;
};

class GameDataImpl implements GameData {
  constructor(readonly name: string, readonly location: string, readonly time: string, readonly visitor: TeamWithScore, readonly home: TeamWithScore) { }

  completed(): boolean {
    return this.visitor.score !== undefined && this.home.score !== undefined;
  }

  winner(): string | undefined {
    if (this.visitor.score !== undefined && this.home.score !== undefined) {
      if (this.visitor.score > this.home.score) {
        return this.visitor.name;
      } else if (this.home.score > this.visitor.score) {
        return this.home.name;
      }
    }

    return undefined;
  }
}

const unknownGame = () => {
  return {} as GameData;
}

const loadGameData = (data: any) => {
  return new GameDataImpl(
    data.name,
    data.location,
    data.time,
    loadTeamWithScore(data.visitor),
    loadTeamWithScore(data.home)
  );
};

export interface Pick {
  game: GameData;
  team: string;
  points: number;
};

const loadPick = (data: any, games: Map<string, GameData>) => {
  const pick: Pick = {
    game: games.get(data.game_name) || unknownGame(),
    team: data.team_name,
    points: parseInt(data.points)
  }

  return pick;
}

export interface Participant {
  name: string;
  tieBreaker: number;
  picks: Array<Pick>;
};

const loadParticipant = (data: any, games: Map<string, GameData>) => {
  const participant: Participant = {
    name: data.name,
    tieBreaker: parseInt(data.tie_breaker),
    picks: data.picks.map((pick: any) => loadPick(pick, games))
  };

  return participant;
};

export interface Data {
  games: Array<GameData>;
  participants: Array<Participant>;
}

// TODO: this should be attached to GameData
export interface GameStats {
  medianPoints: number;
  medianTeam: string;
  totalPoints: number;
  totalPointsRank: number;
  totalPointsWon?: number;
  totalPointsWonRank?: number;
}
*/

// export const computeGameStats = (data: Data, game: Game) => {
//   const allPicks = data.participants.flatMap(p => p.picks).filter(p => p.game === game);
//   const total = allPicks.reduce((acc, cur) => acc + cur.points, 0);
//   const median = medianPickForGame(data, game);

//   if (isCompleted(game)) {
//     const totalWon = allPicks.filter(pick => pick.team === winner(game)).map(pick => pick.points).reduce((acc, cur) => acc + cur, 0);
//   }
// };

// export const averagePickForGame = (data: Data, game: Game) => {
//   const allPicks = data.participants.flatMap(p => p.picks).filter(p => p.game === game);
//   const sum = allPicks.reduce((acc, cur) => acc + (cur.team === game.visitor ? -cur.points : cur.points), 0);
//   const avg = sum / allPicks.length;
//   if (avg < 0) {
//     return { team: game.visitor.name, points: -avg.toFixed(2) };
//   } else {
//     return { team: game.home.name, points: avg.toFixed(2) };
//   }
// };

// export const medianPickForGame = (data: Data, game: Game) => {
//   const allPicks = data.participants.flatMap(p => p.picks).filter(p => p.game === game);
//   const sortedPoints = allPicks.map(pick => pick.team === game.visitor ? -pick.points : pick.points).sort((x, y) => x - y);
//   const medianPoints = sortedPoints[Math.floor(sortedPoints.length / 2)];
//   if (medianPoints < 0) {
//     return { team: game.visitor.name, points: -medianPoints };
//   } else {
//     return { team: game.home.name, points: medianPoints };
//   }
// };

const queryClient = new QueryClient();

const fetchResults = async () => {
  const res1 = Promise.all([
    fetch("https://danhodge-cfb.s3.amazonaws.com/development/2021/results.json"),
    fetch("https://danhodge-cfb.s3.amazonaws.com/development/2021/participants.json")
  ]).then(([r1, r2]) => [r1.json(), r2.json()])
    .then(async ([a, b]) => {
      //const games: Array<Game> = (await a).map(loadGame);
      //const gamesMap = new Map<string, Game>();
      //games.forEach(game => gamesMap.set(game.name, game));
      const bData = await b;
      const teams: Map<number, Team> = loadTeams(bData["teams"]);
      const games: Map<number, Game> = loadGames(bData["games"], teams);

      const aData = await a;
      const results: Map<number, GameOutcome> = loadResults(aData["results"], teams, games);

      const participants: Map<number, Participant> = loadParticipants(bData["participants"], games, results);
      //const changes: Map<number, GameChange> = loadChanges(aData["changes"], teams, games);
      const scores = loadScores(aData["scoring"], participants);

      const data: Data = { games: games, results: results, participants: participants };

      return data;
    });

  return res1;
};

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Shell />
    </QueryClientProvider>
  );
}

function Shell() {
  const { data, isLoading, status } = useQuery("results", fetchResults);

  // useEffect(() => {
  //   Promise.all([
  //     fetch("https://danhodge-cfb.s3.amazonaws.com/2022/participants_2022.json"),
  //     fetch("https://danhodge-cfb.s3.amazonaws.com/2022/results_2022.json"),
  //   ]).then(([p, r]) => {
  //     let x = p.json() as Promise<{ str: "" }>;
  //     setParticipants(p.json() as Promise<{ str: "" });
  //     setResults(r.json());
  //   });
  // });

  // TODO: game data not being loaded correctlty
  const iter = data && data.games.keys()
  iter?.next();
  const firstGameId = iter?.next().value;
  const game = data && data.games.get(firstGameId);
  console.log(`first id = ${firstGameId}, game = ${game}`);

  return isLoading ?
    <div className="App">Loading...</div> :
    (game ?
      <div>
        <div><GameComponent data={data} game={game} /></div>
      </div> : <div>?</div>);
}

export default App;
