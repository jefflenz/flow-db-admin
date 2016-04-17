Meteor.publishComposite 'adminCollectionDoc', (collection, id) ->
	check collection, String
	check id, Match.OneOf(String, Mongo.ObjectID)
	if Roles.userIsInRole this.userId, ['admin']
		find: ->
			adminCollectionObject(collection).find(id)
		children: AdminConfig?.collections?[collection]?.children or []
	else
		@ready()

Meteor.publish 'adminUsers', ->
	if Roles.userIsInRole @userId, ['admin']
		Meteor.users.find()
	else
		@ready()

Meteor.publish 'adminUser', ->
	Meteor.users.find @userId

Meteor.publish 'adminCollectionsCount', ->
	handles = []
	self = @

	_.each AdminTables, (table, name) ->
		id = new Mongo.ObjectID
		count = 0

		table.collection.after.insert ->
			count += 1
			self.changed 'adminCollectionsCount', id, {count: count}

		table.collection.after.remove ->
			count -= 1
			self.changed 'adminCollectionsCount', id, {count: count}

		ready = false
#		handles.push table.collection.find().observeChanges
#			added: ->
#				count += 1
#				#ready and self.changed 'adminCollectionsCount', id, {count: count}
#				#console.log "1"
#			removed: ->
#				count -= 1
#				#ready and self.changed 'adminCollectionsCount', id, {count: count}

		Meteor.setInterval ->
			#self.added 'adminCollectionsCount', id, {collection: name, count: table.collection.find().count()}

			@tmpCount = table.collection.find().count()
			if count != tmpCount
				count = tmpCount
				self.changed 'adminCollectionsCount', id, {count: table.collection.find().count()}
		, 10* 1000

		count = table.collection.find().count()
		self.added 'adminCollectionsCount', id, {collection: name, count: count}
		ready = true

	self.onStop ->
		_.each handles, (handle) -> handle.stop()
	self.ready()

Meteor.publish null, ->
	Meteor.roles.find({})
