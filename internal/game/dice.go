package game

import (
	"math/rand"
	"time"
)

type Color string

const (
	White  Color = "white"
	Yellow Color = "yellow"
	Green  Color = "green"
	Orange Color = "orange"
	Purple Color = "purple"
	Blue   Color = "blue"
)

type Die struct {
	Color Color
	Value int
}

type DiceSet struct {
	Dice []Die
}

func NewDiceSet() *DiceSet {
	rand.Seed(time.Now().UnixNano())

	return &DiceSet{
		Dice: []Die{
			{Color: White, Value: 0},
			{Color: Yellow, Value: 0},
			{Color: Green, Value: 0},
			{Color: Orange, Value: 0},
			{Color: Purple, Value: 0},
			{Color: Blue, Value: 0},
		},
	}
}

func (ds *DiceSet) Roll() {
	for i := range ds.Dice {
		ds.Dice[i].Value = rand.Intn(6) + 1
	}
}

func (ds *DiceSet) GetDiceByColor(color Color) *Die {
	for i := range ds.Dice {
		if ds.Dice[i].Color == color {
			return &ds.Dice[i]
		}
	}
	return nil
}

func (ds *DiceSet) GetLowerDice(chosenValue int) []Die {
	var lower []Die
	for _, die := range ds.Dice {
		if die.Value < chosenValue {
			lower = append(lower, die)
		}
	}
	return lower
}

func (ds *DiceSet) RemoveDice(diceToRemove []Die) {
	for _, toRemove := range diceToRemove {
		for i, die := range ds.Dice {
			if die.Color == toRemove.Color && die.Value == toRemove.Value {
				ds.Dice = append(ds.Dice[:i], ds.Dice[i+1:]...)
				break
			}
		}
	}
}
