function teamClickListener() {
  return (event) => {
    let pointsElem = event.target.parentElement.getElementsByClassName("points")[0]

    if (event.target.classList.contains("chosen")) {
      pointsElem.focus();
    } else if (event.target.classList.contains("not-chosen")) {
      selectTeam(event.target);
      pointsElem.focus();
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

function intValueOrNull(value) {
  return intValueOr(null, value);
}

function intValueOr(defaultValue, value) {
  let isNum = (/^\d+$/.exec(value) !== null);
  if (isNum) {
    return parseInt(value);
  } else {
    return defaultValue;
  }
}

function applyToFirstElementByClassName(element, className, fn) {
  let elem = element.getElementsByClassName(className)[0];
  if (elem !== undefined) {
    return fn(elem);
  }
}

function validatePicks(tableElem, saveButton, totalPoints) {
  let points = Array.from(tableElem.getElementsByClassName("points")).map((elem) => elem.value).map((val) => intValueOrNull(val)).filter((val) => val);
  let sum = points.reduce((memo, value) => memo + value, 0);
  let pointSet = new Set(points);
  let allChosen = Array.from(document.getElementsByTagName("input")).filter((elem) => elem.type == "hidden").every((elem) => elem.value.length > 0);
  let tiebreakerVal = applyToFirstElementByClassName(tableElem, "tiebreaker", (elem) => intValueOr(1, elem.value));
  let champChosen = (applyToFirstElementByClassName(tableElem, "champion", (elem) => intValueOrNull(elem.value)) !== null);

  if (allChosen && champChosen && (tiebreakerVal >= 0) && (tiebreakerVal != 1) && (sum == totalPoints) && (pointSet.size == points.length)) {
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
