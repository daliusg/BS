# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Ship.delete_all
Ship.create(name: 'Carrier', length: 5)
Ship.create(name: 'Battleship', length: 4)
Ship.create(name: 'Destroyer', length: 3)
Ship.create(name: 'Submarine1', length: 2)
Ship.create(name: 'Submarine2', length: 2)
Ship.create(name: 'Patrol1', length: 1)
Ship.create(name: 'Patrol2', length: 1)