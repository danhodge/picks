function teamClickListener() {
  return (event) => {
    if (event.target.classList.contains("chosen")) {
      // no-op
    } else if (event.target.classList.contains("not-chosen")) {
      selectTeam(event.target);
    } else {
      console.log("Error: class list does not include chosen or not-chosen: " + event.target.classList);
    }
  };
}

function pointsUpdateListener(saveButton, totalPoints) {
  return (event) => {
    validatePicks(event.target.closest("table"), saveButton, totalPoints);
  };
}

function validatePicks(tableElem, saveButton, totalPoints) {
  let points = Array.from(tableElem.getElementsByClassName("points")).map((elem) => elem.value).filter((val) => /^\d+$/.exec(val)).map((val) => parseInt(val, 10));
  let sum = points.reduce((memo, value) => memo + value, 0);
  let pointSet = new Set(points);
  let allChosen = Array.from(document.getElementsByTagName("input")).filter((elem) => elem.type == "hidden").every((elem) => elem.value.length > 0);

  if (allChosen && (sum == totalPoints) && (pointSet.size == points.length)) {
    console.log("picks are valid, save enabled");
    saveButton.disabled = false;
  } else {
    console.log("picks are invalid, save disabled: " + allChosen + ", " + sum + ", " + JSON.stringify(Array.from(pointSet)) + ", " + JSON.stringify(points));
    saveButton.disabled = true;
  }
}

function selectTeam(teamElement) {
  let row = teamElement.parentElement;
  for (let td of row.children) {
    if (td.classList.contains("team-name") && td != teamElement) {
      td.classList.remove("chosen");
      td.classList.add("not-chosen");
      break;
    }
  }

  teamElement.classList.remove("not-chosen");
  teamElement.classList.add("chosen");

  let choice = Array.from(row.getElementsByTagName("input")).find((elem) => elem.type == "hidden");
  if (choice != null) {
    choice.value = teamElement.dataset.teamId;
  } else {
    console.log("Error: Unable to update choice");
  }
}
