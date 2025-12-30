package game

import "fmt"

type Player struct {
	Name       string
	ScoreSheet *ScoreSheet
	IsActive   bool
}

func NewPlayer(name string) *Player {
	return &Player{
		Name:       name,
		ScoreSheet: NewScoreSheet(),
		IsActive:   false,
	}
}

func (p *Player) GetTotalScore() int {
	return p.ScoreSheet.GetTotalScore()
}

func (p *Player) GetScoreText() string {
	return fmt.Sprintf("%s: %d points", p.Name, p.GetTotalScore())
}

func (p *Player) String() string {
	return p.Name
}
