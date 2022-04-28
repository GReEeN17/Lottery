// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract Lottery {
    address AddressOfServer;

    constructor() {
        AddressOfServer = msg.sender;
    }

    struct InformationAboutPlayer {
        address address_of_player;
        uint256 amount;
        int8 lucky_number;
    }

    struct InformationAboutOneGame {
        uint256 max_amount_of_players;
        uint256 min_bid;
        uint256 amount_of_players;
        uint256 overall_amount_of_bids;
        uint256 amount_of_winners;
        bool is_ended;
        uint256[] winners_index;
    }

    mapping(uint256 => InformationAboutOneGame) public one_game;
    mapping(uint256 => mapping(uint256 => InformationAboutPlayer))
        public one_player;
    uint256[] game_index;
    uint256 amount_of_games;

    function gameReturn(
        uint256 _index_of_game,
        uint256 _max_amount_of_players,
        uint256 _bid_amount
    ) internal {
        game_index.push(amount_of_games);
        InformationAboutOneGame storage game = one_game[_index_of_game];
        game.max_amount_of_players = _max_amount_of_players;
        game.min_bid = _bid_amount;
        game.overall_amount_of_bids += _bid_amount;
        game.is_ended = false;
    }

    function playerInitialization(
        uint256 _index_of_game,
        uint256 _index_of_player,
        uint256 _bid_amount,
        int8 _lucky_number,
        address _address_of_player
    ) internal {
        InformationAboutPlayer storage player = one_player[_index_of_game][
            _index_of_player
        ];
        player.address_of_player = _address_of_player;
        player.amount = _bid_amount;
        player.lucky_number = _lucky_number;
    }

    modifier is_lucky_number_in_range(int8 _lucky_number) {
        require(
            (_lucky_number >= 0) && (_lucky_number <= 100),
            "Your number must be in range 0-100"
        );
        _;
    }

    function newGame(int8 _lucky_number, uint256 _max_amount_of_players)
        public
        payable
        is_lucky_number_in_range(_lucky_number)
    {
        require(msg.value > 0, "Your bid must be more than 0");
        gameReturn(amount_of_games, _max_amount_of_players, msg.value);
        InformationAboutOneGame storage game = one_game[amount_of_games];
        playerInitialization(
            amount_of_games,
            game.amount_of_players,
            msg.value,
            _lucky_number,
            msg.sender
        );
        game.amount_of_winners = 1;
        amount_of_games++;
        game.amount_of_players++;
    }

    function bid(uint256 _index_of_game, int8 _lucky_number)
        public
        payable
        is_lucky_number_in_range(_lucky_number)
    {
        require(
            (_lucky_number >= 0) && (_lucky_number <= 100),
            "Your number must be in range 0-100"
        );
        InformationAboutOneGame storage game = one_game[_index_of_game];
        require(
            game.amount_of_players < game.max_amount_of_players,
            "You can't join this game. All places are ocupied"
        );
        require(
            msg.value > game.min_bid,
            "To join this game, your bid greater than or equal to minimum bid"
        );
        playerInitialization(
            _index_of_game,
            game.amount_of_players,
            msg.value,
            _lucky_number,
            msg.sender
        );
        game.amount_of_players++;
        game.overall_amount_of_bids += msg.value;
        if (game.amount_of_players > 3) {
            game.amount_of_winners = (3 * game.amount_of_players) / uint256(10);
        }
    }

    //function random() private view returns(uint){
    //return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    //}

    function abs(int8 x) private pure returns (int8) {
        return x >= 0 ? x : -x;
    }

    function transactToWinner(uint256 _index_of_game) public payable {
        InformationAboutOneGame storage game = one_game[_index_of_game];
        require(game.is_ended == true, "This game was not ended yet");
        for (uint256 i; i < game.amount_of_winners; i++) {
            payable(
                one_player[_index_of_game][game.winners_index[i]]
                    .address_of_player
            ).transfer(game.overall_amount_of_bids / game.amount_of_winners);
        }
    }

    function revealWiners(uint256 _index_of_game) public {
        InformationAboutOneGame storage game = one_game[_index_of_game];
        int8[] memory lucky_numbers = new int8[](game.amount_of_players);
        for (uint256 i; i < game.amount_of_players; i++) {
            lucky_numbers[i] = one_player[_index_of_game][i].lucky_number;
        }
        int8 lucky;
        if (game.amount_of_players > 3) {
            uint256 winners_amount;
            for (int8 i; i < 101; i++) {
                bool is_max = false;
                for (uint256 j; j < game.amount_of_players; j++) {
                    if (winners_amount == game.amount_of_winners) {
                        is_max = true;
                        break;
                    }
                    if (
                        (lucky_numbers[j] == lucky - i) ||
                        (lucky_numbers[j] == lucky + i)
                    ) {
                        game.winners_index.push(j);
                        winners_amount++;
                    }
                }
                if (is_max) {
                    break;
                }
            }
        } else {
            game.amount_of_winners = 1;
            if (game.amount_of_players == 1) {
                game.winners_index.push(0);
            }
            if (game.amount_of_players == 2) {
                if (
                    abs(int8(lucky_numbers[0] - lucky)) <
                    abs(int8(lucky_numbers[1] - lucky))
                ) {
                    game.winners_index.push(0);
                } else {
                    game.winners_index.push(1);
                }
            }
            if (game.amount_of_players == 3) {
                if (
                    abs(int8(lucky_numbers[0] - lucky)) <
                    abs(int8(lucky_numbers[1] - lucky))
                ) {
                    if (
                        abs(int8(lucky_numbers[0] - lucky)) <
                        abs(int8(lucky_numbers[2] - lucky))
                    ) {
                        game.winners_index.push(0);
                    } else {
                        game.winners_index.push(2);
                    }
                } else {
                    if (
                        abs(int8(lucky_numbers[1] - lucky)) <
                        abs(int8(lucky_numbers[2] - lucky))
                    ) {
                        game.winners_index.push(1);
                    } else {
                        game.winners_index.push(2);
                    }
                }
            }
        }
        game.is_ended = true;
    }
}
