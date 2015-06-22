
// Copyright (c) 2015, Evan Summers (twitter.com/evanxsummers)
// ISC license, see http://github.com/evanx/redex/LICENSE

import assert from 'assert';
import bunyan from 'bunyan';

const Redis = RedexGlobal.require('lib/Redis');

const { redex } = RedexGlobal;

const logger = bunyan.createLogger({name: 'RedisHttpRequestImporter', level: RedexGlobal.loggerLevel});

const redis = new Redis();

export default class RedisHttpRequestImporter {

   constructor(config) {
      assert(config.queue.in, 'queue.in');
      assert(config.queue.reply, 'queue.reply');
      assert(config.queue.pending, 'queue.pending');
      assert(config.timeout, 'timeout');
      assert(config.route, 'route');
      this.config = config;
      logger.info('constructor', this.constructor.name, this.config);
      this.count = 0;
      this.popTimeout = this.config.popTimeout || 0;
      this.redis = new Redis();
      this.pop();
   }

   addedPending(messageId, redisReply) {
      logger.debug('addPending', messageId);
   }

   removePending(messageId, redisReply) {
      logger.debug('removePending', messageId);
   }

   revertPending(messageId, redisReply, error) {
      logger.warn('revertPending:', messageId, error, error.stack);
   }


   async pop() {
      try {
         logger.debug('pop', this.config.queue.in);
         var redisReply = await this.redis.brpoplpush(this.config.queue.in,
            this.config.queue.pending, this.popTimeout);
         this.count += 1;
         var messageId = this.count;
         var expiryTime = new Date().getTime() + this.config.timeout;
         this.addedPending(messageId, redisReply);
         logger.debug('redisReply', redisReply);
         let message = JSON.parse(redisReply);
         logger.info('pop:', message);
         let reply = await redex.import(message, {messageId}, this.config);
         logger.info('reply:', reply);
         await this.redis.lpush(this.config.queue.reply, JSON.stringify(reply));
         this.removePending(messageId, redisReply);
         //throw new Error('test');
         this.pop();
      } catch (error) {
         this.redis.lpush(this.config.queue.error, JSON.stringify(error));
         this.revertPending(messageId, redisReply, error);
         setTimeout(() => this.pop(), config.errorWaitMillis || 1000);
      }
   }
}
