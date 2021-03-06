
// S.

'use strict'

import HiveAPI from 'hiveapi'
import fs from 'fs'
import fetch from 'node-fetch'

async function main() {
	const token = JSON.parse(fs.readFileSync('./token.json', 'utf-8'))
	const api = new HiveAPI(token)

	const date = new Date()

	console.log('Sending with date:', date)

	const farms = await api.farms.all()

	return Promise.all(farms.map(async farm => {
		const workers = await farm.workers.all()

		return Promise.all(workers.map(worker => {
			const url = 'https://cryptotech-crm-default-rtdb.europe-west1.firebasedatabase.app/consumption/' +
				`${farm.id}/${worker.id}/${date.getFullYear()}/${date.getMonth() + 1}/${date.getDate()}/${date.getHours()}/${date.getMinutes()}.json`

			return fetch(url, { method: 'PUT', body: worker.data.stats.power_draw || 0 })
				.then(() => console.log('[SENT]', farm.name, '-', worker.name, '-', consumption, 'W'))
				.catch(e => console.error('[ERROR]', farm.name, '-', worker.name))
		}))
	}))
}

main()
	.then(() => console.log('main done'))
	.catch(e => console.error('main error', e))

// EOF
