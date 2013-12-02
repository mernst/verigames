import json

def process(filename):
	all_pageloads = {}
	user_level_data = []
	num_lines = sum(1 for count_line in open(filename + '.jsons'))
	with open(filename + '.jsons') as fin:
		linenum = 0
		for line in fin:
			if linenum % 10 == 0:
				print 'Line %s/%s' % (linenum, num_lines)
			linenum += 1
			userdata = json.loads(line)
			pl = userdata.get('pageloads', [])
			for pageload in pl:
				pl_detail_string = pageload.get('pl_detail', '{}')
				pl_info = json.loads(pl_detail_string)
				pl_info['uid'] = pageload.get('uid')
				pl_info['log_ts'] = pageload.get('log_ts')
				pl_info['referrer_host'] = pageload.get('referrer_host')
				pl_info['sessionid'] = pageload.get('sessionid')
				if pl_info['sessionid'] is not None:
					all_pageloads[pl_info['sessionid']] = pl_info
			levs = userdata.get('levels', [])
			for level in levs:
				user_level_info = {}
				user_level_info['qid'] = level.get('qid')
				lev_detail_string = level.get('q_detail', '{}')
				lev_details = json.loads(lev_detail_string)
				user_level_info['levelName'] = lev_details.get('levelName')
				lev_info = lev_details.get('levelInfo', {})
				user_level_info['score'] = lev_info.get('m_score')
				user_level_info['targetscore'] = lev_info.get('m_targetScore')
				user_level_info['sessionid'] = level.get('sessionid')
				user_level_info['log_q_ts'] = level.get('log_q_ts')
				quest_end = level.get('questend') or {}
				endtime = quest_end.get('log_q_ts')
				actions = level.get('actions')
				if endtime is None:
					endtime = int(user_level_info['log_q_ts'])
					for action in actions:
						atime = int(action.get('log_ts', 0))
						if atime > endtime:
							endtime = atime
				user_level_info['endtime'] = endtime
				user_level_info['actions'] = len(actions)
				pl_info = all_pageloads.get(user_level_info['sessionid'])
				if pl_info is None:
					if user_level_info['sessionid'] is not None:
						print 'No pageload found for sessionid: %s' % user_level_info['sessionid']
				else:
					for pl_key in pl_info:
						user_level_info['pl_%s' % pl_key] = pl_info[pl_key]
				user_level_data.append(user_level_info)
	with open('new_%s.json' % filename, 'w') as fout:
		fout.write(json.dumps(user_level_data))
	
			