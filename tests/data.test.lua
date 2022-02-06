require 'tests.mock'

package.path = package.path .. ';src/autorun/?.lua'

local STATE = require 'mhrise-coavins-dps.state'
local ENUM  = require 'mhrise-coavins-dps.enum'
local DATA  = require 'mhrise-coavins-dps.data'

local function initializeMockBossMonster()
	-- automatically puts boss into cache
	local enemy = MockEnemy:create()
	DATA.initializeBossMonster(enemy)
	local boss = STATE.LARGE_MONSTERS[enemy]
	return boss
end

describe("data:", function()
	setup(function()
		STATE.MANAGER.MESSAGE = MockMessageManager:create()
	end)

	describe("addDamageToBoss", function()

		it("accumulates one attacker", function()
			local boss = initializeMockBossMonster()

			DATA.addDamageToBoss(boss, 1, 0, 100, 200, 400)

			local s = boss.damageSources[1]

			local expected = 100
			local actual = s.counters['weapon'].physical
			assert.is_equal(expected, actual)

			expected = 200
			actual = s.counters['weapon'].elemental
			assert.is_equal(expected, actual)

			expected = 400
			actual = s.counters['weapon'].condition
			assert.is_equal(expected, actual)
		end)

		it("accumulates four attackers", function()
			local boss = initializeMockBossMonster()

			DATA.addDamageToBoss(boss, 0, 0, 101, 202, 403)
			DATA.addDamageToBoss(boss, 1, 0, 201, 402, 803)
			DATA.addDamageToBoss(boss, 2, 0, 401, 802, 103)
			DATA.addDamageToBoss(boss, 3, 0, 801, 102, 203)

			local s, expected, actual

			s = boss.damageSources[0]
			expected = 101
			actual = s.counters['weapon'].physical
			assert.is_equal(expected, actual)
			expected = 202
			actual = s.counters['weapon'].elemental
			assert.is_equal(expected, actual)
			expected = 403
			actual = s.counters['weapon'].condition
			assert.is_equal(expected, actual)

			s = boss.damageSources[1]
			expected = 201
			actual = s.counters['weapon'].physical
			assert.is_equal(expected, actual)
			expected = 402
			actual = s.counters['weapon'].elemental
			assert.is_equal(expected, actual)
			expected = 803
			actual = s.counters['weapon'].condition
			assert.is_equal(expected, actual)

			s = boss.damageSources[2]
			expected = 401
			actual = s.counters['weapon'].physical
			assert.is_equal(expected, actual)
			expected = 802
			actual = s.counters['weapon'].elemental
			assert.is_equal(expected, actual)
			expected = 103
			actual = s.counters['weapon'].condition
			assert.is_equal(expected, actual)

			s = boss.damageSources[3]
			expected = 801
			actual = s.counters['weapon'].physical
			assert.is_equal(expected, actual)
			expected = 102
			actual = s.counters['weapon'].elemental
			assert.is_equal(expected, actual)
			expected = 203
			actual = s.counters['weapon'].condition
			assert.is_equal(expected, actual)
		end)

	end)

	describe("numHit", function()

		it("counts correctly", function()
			local boss = initializeMockBossMonster()

			DATA.addDamageToBoss(boss, 1, 0, 500)
			DATA.addDamageToBoss(boss, 1, 0, 400)
			DATA.addDamageToBoss(boss, 1, 0, 300)
			DATA.addDamageToBoss(boss, 1, 0, 200)

			local attacker_type = ENUM.ATTACKER_TYPES[0]
			local expected = 4
			local actual = boss.damageSources[1].counters[attacker_type].numHit

			assert.is_equal(expected, actual)
		end)

	end)

	describe("maxHit", function()

		it("counts correctly", function()
			local boss = initializeMockBossMonster()

			DATA.addDamageToBoss(boss, 1, 0, 500)
			DATA.addDamageToBoss(boss, 1, 0, 400)
			DATA.addDamageToBoss(boss, 1, 0, 300)
			DATA.addDamageToBoss(boss, 1, 0, 200)

			local attacker_type = ENUM.ATTACKER_TYPES[0]
			local expected = 500
			local actual = boss.damageSources[1].counters[attacker_type].maxHit

			assert.is_equal(expected, actual)
		end)

	end)

	describe("ailment buildup", function()

		it("gets set on boss", function()
			local boss = initializeMockBossMonster()

			DATA.addDamageToBoss(boss, 1, 0, 100, 0, 50, 5)

			local expected = 50
			local actual = boss.ailment.buildup[5][1]

			assert.is_equal(expected, actual)
		end)

		it("accumulates for one attacker", function()
			local boss = initializeMockBossMonster()

			DATA.addDamageToBoss(boss, 1, 0, 100, 0, 1, 5)
			DATA.addDamageToBoss(boss, 1, 0, 100, 0, 2, 5)
			DATA.addDamageToBoss(boss, 1, 0, 100, 0, 4, 5)

			local expected = 7
			local actual = boss.ailment.buildup[5][1]

			assert.is_equal(expected, actual)
		end)

		it("accumulates for three attackers", function()
			local boss = initializeMockBossMonster()

			DATA.addDamageToBoss(boss, 1, 0, 100, 0, 1, 5)
			DATA.addDamageToBoss(boss, 2, 0, 100, 0, 2, 5)
			DATA.addDamageToBoss(boss, 654, 0, 100, 0, 4, 5)

			assert.is_equal(1, boss.ailment.buildup[5][1])
			assert.is_equal(2, boss.ailment.buildup[5][2])
			assert.is_equal(4, boss.ailment.buildup[5][654])
		end)

	end)

	describe("calculateAilmentContrib", function()

		it("distributes blast fairly #1", function()
			local boss = initializeMockBossMonster()

			DATA.addDamageToBoss(boss, 1, 0, 100, 0, 100, 5)
			DATA.addDamageToBoss(boss, 2, 0, 100, 0, 100, 5)
			DATA.addDamageToBoss(boss, 3, 0, 100, 0, 200, 5)

			DATA.calculateAilmentContrib(boss, 5)

			assert.is_equal(0.25, boss.ailment.share[5][1])
			assert.is_equal(0.25, boss.ailment.share[5][2])
			assert.is_equal(0.5, boss.ailment.share[5][3])
		end)

		it("distributes blast fairly #2", function()
			local boss = initializeMockBossMonster()

			DATA.addDamageToBoss(boss, 0, 0, 100, 0, 100, 5)
			DATA.addDamageToBoss(boss, 1, 0, 100, 0, 100, 5)
			DATA.addDamageToBoss(boss, 2, 0, 100, 0, 200, 5)
			DATA.addDamageToBoss(boss, 3, 0, 100, 0, 400, 5)

			DATA.calculateAilmentContrib(boss, 5)

			assert.is_equal(0.125, boss.ailment.share[5][0])
			assert.is_equal(0.125, boss.ailment.share[5][1])
			assert.is_equal(0.25, boss.ailment.share[5][2])
			assert.is_equal(0.5, boss.ailment.share[5][3])
		end)

		it("distributes poison fairly #1", function()
			local boss = initializeMockBossMonster()

			DATA.addDamageToBoss(boss, 0, 0, 100, 0, 100, 4)
			DATA.addDamageToBoss(boss, 1, 0, 100, 0, 100, 4)
			DATA.addDamageToBoss(boss, 2, 0, 100, 0, 200, 4)
			DATA.addDamageToBoss(boss, 3, 0, 100, 0, 400, 4)

			DATA.calculateAilmentContrib(boss, 4)

			assert.is_equal(0.125, boss.ailment.share[4][0])
			assert.is_equal(0.125, boss.ailment.share[4][1])
			assert.is_equal(0.25, boss.ailment.share[4][2])
			assert.is_equal(0.5, boss.ailment.share[4][3])
		end)

	end)

	describe("damage counter", function()

		it("is empty when initialized", function()
			local c = DATA.initializeDamageCounter()

			assert.is_equal(c.physical, 0.0)
			assert.is_equal(c.elemental, 0.0)
			assert.is_equal(c.condition, 0.0)

			local total = DATA.getTotalDamageForDamageCounter(c)

			assert.is_equal(0, total)
		end)

		it("merges correctly", function ()
			local a = DATA.initializeDamageCounter()
			local b = DATA.initializeDamageCounter()
			local result = DATA.initializeDamageCounter()

			a.physical = 100
			b.physical = 100
			result.physical = 200

			a.elemental = 405
			b.elemental = 5
			result.elemental = 410

			a.condition = 999
			b.condition = 3
			result.condition = 1002

			local actual = DATA.mergeDamageCounters(a,b)

			assert.are_same(result, actual)
		end)

		it("shows the right total", function()
			local c = DATA.initializeDamageCounter()

			c.physical = 100
			c.elemental = 212
			c.condition = 323

			local actual = DATA.getTotalDamageForDamageCounter(c)

			assert.is_equal(100 + 212, actual)
		end)

	end)

	describe("damage source", function()

		it("is empty when initialized", function()
			local s = DATA.initializeDamageSource()

			assert.is_nil(s.id)
		end)

	end)

end)