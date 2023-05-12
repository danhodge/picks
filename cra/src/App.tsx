import { timeStamp } from 'console';
import React, { useEffect, useState } from 'react';
import { QueryClient, QueryClientProvider, useQuery } from 'react-query';
import internal from 'stream';
import { TemplateExpression, textChangeRangeIsUnchanged } from 'typescript';
import './App.css';
import GameComponent from './Game';
import { Scoreboard } from './Scoreboard';
import { DefaultParams, Link, Redirect, Route, Switch, useLocation, useRoute } from "wouter";
import { ParticipantComponent } from './Participant';
import { SeasonSelector } from './SeasonSelector';


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

// TODO: make season a property on Game
export interface Game {
  id: number;
  name: string;
  location: string;
  time: string;
  visitor: Team;
  home: Team;
  prevVisitor?: Team;
  prevHome?: Team;
};

export interface GameOutcome {
  status: string;
  pointsAwardedTo?: Team;
  forfeitedBy?: Team;
  finalScores?: Map<number, number>;
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
  id: number;
  name: string;
  tieBreaker: number;
  picks: Map<number, Pick>;
  score: Score;
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
  seasons: Array<Season>;
  season: Season;
  games: Map<number, Game>;
  participants: Map<number, Participant>;
  results: Map<number, GameOutcome>;
}

export interface Season {
  path: string;
  name: string;
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

const loadSeasons = (data: any) => {
  var seasons = new Array<Season>();
  for (const season of data) {
    seasons.push({ path: season.path, name: season.name });
  }

  return seasons;
}

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

    if (game && winner) {
      const outcome: GameOutcome = {
        status: data[id].status,
        pointsAwardedTo: winner,
      };
      if (scores.size === 2) {
        outcome.finalScores = scores;
      }
      const forfeitedBy = teams.get(data[id].forfeited_by);
      if (forfeitedBy) {
        outcome.forfeitedBy = forfeitedBy;
      }
      results.set(id, outcome);
    }
  }

  return results;
}

const loadParticipants = (data: any, games: Map<number, Game>, results: Map<number, GameOutcome>) => {
  const participants = new Map<number, Participant>();
  for (const idStr in data) {
    const id = parseInt(idStr);
    participants.set(id, loadParticipant(data[id], id, games, results));
  }

  return participants;
}

const applyChanges = (data: any, teams: Map<number, Team>, games: Map<number, Game>) => {
  for (const idStr in data) {
    const gameId = parseInt(idStr);
    const game = games.get(gameId);
    if (game) {
      for (const change of data[idStr]) {
        const origTeam = teams.get(parseInt(change.original_team_id));
        const newTeam = teams.get(parseInt(change.new_team_id));

        if (origTeam && newTeam) {
          if (game.home === origTeam) {
            game.home = newTeam;
            game.prevHome = origTeam;
          }
          if (game.visitor === origTeam) {
            game.visitor = newTeam;
            game.prevVisitor = origTeam;
          }
        }
      }
    }
  }
}

const loadPick = (data: any, game: Game | undefined, totalPoints: number) => {
  if (!game) {
    return undefined;
  }

  const team = [(game.prevHome || game.home), (game.prevVisitor || game.visitor)].find((team: Team) => team.id === data.team_id);
  if (team) {
    return { game: game, team: team, points: data.points, totalPoints: totalPoints };
  } else {
    return undefined;
  }
}

const loadParticipant = (data: any, id: number, games: Map<number, Game>, results: Map<number, GameOutcome>) => {
  const picks = new Map<number, Pick>();
  const participant: Participant = {
    id: id,
    name: data.name,
    tieBreaker: data.tiebreaker,
    picks: picks,
    score: {
      pointsWon: 0,
      pointsLost: 0,
      pointsRemaining: 0,
      scoringAvg: 0,
      wins: 0,
      losses: 0
    }
  };
  var pointTotal = 0;
  for (const gameIdStr in data.picks) {
    const gameId = parseInt(gameIdStr);
    const game = games.get(gameId);
    const pick = loadPick(data.picks[gameId], game, pointTotal);

    if (game && pick) {
      const outcome = results.get(game.id);
      if (outcome && (outcome.status === "completed" || outcome.status === "forfeited") && outcome.pointsAwardedTo === pick.team) {
        pointTotal += pick.points;
        pick.totalPoints = pointTotal;
      }
      picks.set(gameId, pick);
    }
  }

  return participant;
};

const loadScores = (data: any, participants: Map<number, Participant>) => {
  for (const participantIdStr in data) {
    const participantId = parseInt(participantIdStr);
    const participant = participants.get(participantId);
    const scoringData = data[participantId];

    if (participant && scoringData) {
      participant.score = {
        pointsWon: scoringData['points'].won,
        pointsLost: scoringData['points'].lost,
        pointsRemaining: scoringData['points'].remaining,
        scoringAvg: scoringData['points'].average,
        wins: scoringData['games'].won,
        losses: scoringData['games'].lost,
      }
    }
  }

  return participants;
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
  if (!outcome || !outcome.finalScores) {
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

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnMount: false,
      refetchOnReconnect: false,
      refetchOnWindowFocus: false,
    }
  }
});

/*
[{path: "2021", name: "2021-22"}, {path: "2021a", name: "2021-22 test"}]
*/

const fetchResults = async (season: string | undefined) => {
  // TODO: handle non-2xx response codes gracefully
  return fetch("https://danhodge-cfb.s3.amazonaws.com/development/seasons.json")
    .then((result) => result.json())
    .then(async (seasons) => {
      const seasonData = loadSeasons(await seasons);
      if (seasonData.length === 0) {
        return {
          seasons: seasonData,
          season: { name: "U", path: "U" },
          games: new Map<number, Game>(),
          results: new Map<number, GameOutcome>(),
          participants: new Map<number, Participant>(),
        };
      } else {
        const requestedSeason = seasonData.find((val) => (season !== "unknown") && (val.path === season));
        const actualSeason = (requestedSeason) ? requestedSeason : seasonData[0];
        const path = actualSeason.path;
        const resultsUrl = `https://danhodge-cfb.s3.amazonaws.com/development/${path}/results.json`;
        const participantsUrl = `https://danhodge-cfb.s3.amazonaws.com/development/${path}/participants.json`;

        return Promise
          .all([fetch(resultsUrl), fetch(participantsUrl)])
          .then(([resultData, participantData]) => [resultData.json(), participantData.json()])
          .then(async ([resultJSON, participantJSON]) => {
            const participantData = await participantJSON;
            const teams: Map<number, Team> = loadTeams(participantData["teams"]);
            const games: Map<number, Game> = loadGames(participantData["games"], teams);

            const resultData = await resultJSON;
            const results: Map<number, GameOutcome> = loadResults(resultData["results"], teams, games);
            applyChanges(resultData["changes"], teams, games);

            const participants: Map<number, Participant> = loadParticipants(participantData["participants"], games, results);
            loadScores(resultData["scoring"], participants);

            const data: Data = {
              seasons: seasonData,
              season: actualSeason,
              games: games,
              results: results,
              participants: participants
            };

            return data;
          });
      }
    })
};

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Shell />
    </QueryClientProvider>
  );
}

function Shell() {
  const [isRoot, _] = useRoute("/");
  const [isScoreboard, scoreboardParams] = useRoute("/:season");
  const [isGame, gameParams] = useRoute("/:season/games/:id");
  const [isParticipant, participantParams] = useRoute("/:season/participants/:id");
  const [location, setLocation] = useLocation();

  var view = "redirect";
  var params = null;
  if (isGame) {
    view = "game";
    params = gameParams;
  } else if (isParticipant) {
    view = "participant";
    params = participantParams;
  } else if (isScoreboard) {
    view = "scoreboard";
    params = scoreboardParams;
  }

  const [season, setSeason] = useState(params ? params.season : "unknown");

  const { data, isLoading, status } = useQuery(["results", season], () => fetchResults(season));

  if (view === "redirect") {
    const now = new Date(Date.now());
    const curYear = (now.getMonth() === 0 && now.getDate() < 15) ? now.getFullYear() - 1 : now.getFullYear();
    return <Redirect to={"/" + curYear} />;
  }

  const setSeasonLocation = (season: string) => {
    setSeason(season);
    setLocation(`/${season}`);
  };

  const doneLoading = !isLoading && data;
  return doneLoading ?
    <div className="flex flex-col h-screen bg-yellow-100 container min-w-full">
      <header className="bg-yellow-200 container flex flex-row items-center sticky top-0 left-0 min-w-full h-14 px-4">
        <div className="flex-none basis-1/8 text-sm">
          <SeasonSelector seasons={data.seasons} selected={data.season} setSeason={setSeasonLocation} />
        </div>
        {view === "scoreboard" ?
          <div></div> :
          <div className="flex-none text-center basis-1/4 text-base font-semibold">
            <Link href={"/" + data.season.path}>
              <span className="hover:text-orange-500 cursor-pointer">Standings</span>
            </Link>
          </div>
        }
      </header>
      <main className="flex-1 flex flex-wrap">
        {loaded(data, view, params)}
      </main>
      <div className="bg-yellow-100 h-screen p-6 flex flex-grow" />
    </div > :
    loading();
}

const loading = () => {
  return <div className="App">Loading...</div>;
}

const loaded = (data: Data, view: string, params: DefaultParams | null) => {
  return (view === "scoreboard") ?
    <Scoreboard season={data.season} participants={data.participants} /> :
    (view === "game") ? viewGame(data, params) : viewParticipant(data, params);
}

const viewGame = (data: Data, params: DefaultParams | null) => {
  var game;
  if (params && params.id) {
    game = data.games.get(parseInt(params.id));
  }

  return (game) ?
    <GameComponent data={data} game={game} /> :
    <Scoreboard participants={data.participants} season={data.season} />
}

const viewParticipant = (data: Data, params: DefaultParams | null) => {
  var participant;
  if (params && params.id) {
    participant = data.participants.get(parseInt(params.id));
  }

  return (participant) ? <ParticipantComponent data={data} participant={participant} /> : <Scoreboard participants={data.participants} season={data.season} />;
}

export default App;
